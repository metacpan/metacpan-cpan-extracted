package PBS::Client;
use strict;
use vars qw($VERSION);
use Carp;
use File::Temp qw(tempfile);
$VERSION = '0.11';

#------------------------------------------------
# Submit jobs to PBS
#
# Included methods:
# - Construct PBS client object
#     $client = PBS::Client->new();
#
# - Submit jobs
#     $client->qsub($job);
#     -- $client -- client object
#     -- $job ----- job object
#
# - Generate job script without job submission
#     $client->genScript($job);
#     -- $client -- client object
#     -- $job ----- job object
#------------------------------------------------


#------------------------
# Constructor method
#
# <IN>
# $class -- client object
# %hash --- argument hash
#
# <OUT>
# $self -- client object
sub new
{
    my ($class, %hash) = @_;
    my $self = \%hash;
    return bless($self, $class);
}
#------------------------


#--------------------------
# Generic attribute methods
sub AUTOLOAD
{
    my ($self, $key) = @_;
    my $attr = our $AUTOLOAD;
    $attr =~ s/.*:://;
    return if ($attr eq 'DESTROY');        # ignore destructor
    $self->{$attr} = $key if (defined $key);
    return($self->{$attr});
}
#--------------------------


#-------------------------------------------------------------------
# Submit PBS jobs by qsub command
# - called subroutines: getScript(), _numPrevJob() and _qsubDepend()
#
# <IN>
# $self -- client object
# $job --- job object
#
# <OUT>
# \@pbsid -- array reference of PBS job ID
sub qsub
{
    my ($self, $job) = @_;

    #----------------------------------------------------------
    # Codes for backward compatatible with old private software
    #----------------------------------------------------------
    if (!ref($job) || ref($job) eq 'ARRAY')
    {
        $self->cmd($job);
        &qsub($self, $self);
    }

    #-----------------------------------------------
    # Dependency: count number of previous jobs
    #-----------------------------------------------
    my $on = &_numPrevJob($job);
    $job->{depend}{on} = [$on] if ($on);
    my $file = $job->{script};
    my @pbsid = ();

    #-----------------------------------------------
    # Single job
	# Thanks to Demian Ricchardi for a bug fix
    #-----------------------------------------------
    if (!ref($job->{cmd}))
    {
        my $tempFile = &genScript($self, $job);           # generate script
        my $out = &call_qsub('qsub', $tempFile);          # submit script
        my $pbsid = ($out =~ /^(\d+)/)[0];                # get pid
        rename($tempFile, "$file.$pbsid");                # rename script
        push(@pbsid, $pbsid);
        $job->pbsid($pbsid);
    }
    #-----------------------------------------------
    # Multiple (matrix of) jobs
	# Thanks to Demian Ricchardi for a bug fix
    #-----------------------------------------------
    else
    {
        my $subjob = $job->copy;
        for (my $i = 0; $i < @{$job->{cmd}}; $i++)
        {
            # Get command
            my $list = ${$job->{cmd}}[$i];
            my $cmd = (ref $list)? (join("\n", @$list)): $list;
            $subjob->{cmd} = $cmd;

            # Generate and submit job script
            my $tempFile = &genScript($self, $subjob);    # generate script
            my $out = &call_qsub('qsub', $tempFile);      # submit script
            my $pbsid = ($out =~ /^(\d+)/)[0];            # get pid
            rename($tempFile, "$file.$pbsid");            # rename script
            push(@pbsid, $pbsid);
        }
        $job->pbsid(\@pbsid);
    }

    #-----------------------------------------------
    # Dependency: submit previous and following jobs
    #-----------------------------------------------
    &_qsubDepend($self, $job, \@pbsid);

    return(\@pbsid);
}
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Thanks to Sander Hulst
sub call_qsub
{
    my @args = @_;

    # If the qsub command fails, for instance, pbs_server is not running,
    # PBS::Client's qsub should not silently ignore. Disable any reaper
    # functions so the exit code can be captured
    use Symbol qw(gensym);
    use IPC::Open3;
	my $stdout = gensym();
	my $stderr = gensym();
    {
        local $SIG{CHLD} = sub{};
        my $pid = open3(gensym, $stdout, $stderr, @args);
        waitpid($pid,0);
    }
    confess <$stderr> if ($?);
    return <$stdout>;
}
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Dispatch PBS jobs by dispatch and qsub command
# - Codes for backward compatible with old private software
# - called subroutines: getScript()
#
# <IN>
# $self -- server object
# $job --- job object
#
# <OUT>
# \@pbsid -- array reference of PBS job ID
sub dispatch
{
    my ($self, $job) = @_;
    my $file = $job->{script};

    #-----------------------------------------------
    # Dependency: count number of previous jobs
    #-----------------------------------------------
    my $on = &_numPrevJob($job);
    $job->{depend}{on} = [$on] if ($on);
    my @pbsid = ();

    #---------
    # Dispatch
    #---------
    my $subjob = $job->copy;
    for (my $i = 0; $i < @{$job->{cmd}}; $i++)
    {
        #--------------
        # Dispatch jobs
        #--------------
        my $list = ${$job->{cmd}}[$i];
        my $djob = (ref $list)? (join("\n", @$list)): $list;
        $djob =~ s/\\/\\\\/g;
        $djob =~ s/"/\\\"/g;

        #-----------------
        # Dispatch command
        #-----------------
        my $cmd = 'echo "'."\n$djob\n".'" | dispatch';
        $subjob->{cmd} = $cmd;

        #-------------------------------
        # Generate and submit job script
        #-------------------------------
        my $numJob = (ref $list)? (scalar(@$list)): 1;
        $subjob->nodes($numJob) if (!defined $subjob->{nodes});
        my $tempFile = &genScript($self, $subjob);    # generate script
        my $out = `qsub $tempFile`;                   # submit script
        my $pbsid = ($out =~ /^(\d+)/)[0];            # grab pid
        rename($tempFile, "$file.$pbsid");            # rename script
        push(@pbsid, $pbsid);
    }
    $job->pbsid(\@pbsid);

    #-------------------------------------------------
    # Dependency: dispatch previous and following jobs
    #-------------------------------------------------
    &_dphDepend($self, $job, \@pbsid);

    return(\@pbsid);
}
#-------------------------------------------------------------------


#-----------------------------------------------------------------
# Generate shell script from command string array
# - called subroutines: _trace(), _nodes(), _stage() and _depend()
# - called by qsub()
#
# <IN>
# $self -- client object
# $job --- job object
#
# <OUT>
# $file -- filename of job script
sub genScript
{
    my ($self, $job) = @_;

    #-------------------------
    # Process the queue string
    #-------------------------
    my $queue = '';
    $queue .= $job->{queue} if (defined $job->{queue});
    $queue .= '@'.$self->{server} if (defined $self->{server});

    #-------------------------------
    # Process the mail option string
    #-------------------------------
    my $mailOpt;
    if (defined $job->{mailopt})
    {
        $mailOpt = $job->{mailopt};
        $mailOpt =~ s/\s*,\s*//;
    }

    #---------------------
    # Generate node string
    #---------------------
    my $nodes = &_nodes($job);

    #------------------------------------
    # Set internal variable:
    # - temporary file for the job script
    #------------------------------------
    my (undef, $file) = tempfile(DIR => $job->{wd});
    $job->_tempScript($file);

    #------------------------
    # PBS request option list
    #------------------------
    open(SH, ">$file") || confess "Can't write $file";
    print SH "#!$job->{shell}\n\n";
    print SH "#PBS -N $job->{name}\n";
    print SH "#PBS -d $job->{wd}\n";
    print SH "#PBS -e $job->{efile}\n" if (defined $job->{efile});
    print SH "#PBS -o $job->{ofile}\n" if (defined $job->{ofile});
    print SH "#PBS -q $queue\n" if ($queue);
    print SH "#PBS -W x=PARTITION:$job->{partition}\n" if
        (defined $job->{partition});
    print SH "#PBS -W stagein=".&_stage('in', $job->{stagein})."\n" if
        (defined $job->{stagein});
    print SH "#PBS -W stageout=".&_stage('out', $job->{stageout})."\n" if
        (defined $job->{stageout});
    print SH "#PBS -M ".&_mailList($job->{maillist})."\n" if
        (defined $job->{maillist});
    print SH "#PBS -m ".$mailOpt."\n" if (defined $mailOpt);
    print SH "#PBS -v ".&_varList($job->{vars})."\n" if (defined $job->{vars});
    print SH "#PBS -A $job->{account}\n" if (defined $job->{account});
    print SH "#PBS -p $job->{pri}\n" if (defined $job->{pri});
    print SH "#PBS -l nodes=$nodes\n";
    print SH "#PBS -l host=$job->{host}\n" if (defined $job->{host});
    print SH "#PBS -l mem=$job->{mem}\n" if (defined $job->{mem});
    print SH "#PBS -l pmem=$job->{pmem}\n" if (defined $job->{pmem});
    print SH "#PBS -l vmem=$job->{vmem}\n" if (defined $job->{vmem});
    print SH "#PBS -l pvmem=$job->{pvmem}\n" if (defined $job->{pvmem});
    print SH "#PBS -l cput=$job->{cput}\n" if (defined $job->{cput});
    print SH "#PBS -l pcput=$job->{pcput}\n" if (defined $job->{pcput});
    print SH "#PBS -l walltime=$job->{wallt}\n" if (defined $job->{wallt});
    print SH "#PBS -l nice=$job->{nice}\n" if (defined $job->{nice});
    print SH "#PBS -l prologue=$job->{prologue}\n" if
        (defined $job->{prologue});
    print SH "#PBS -l epilogue=$job->{epilogue}\n" if
        (defined $job->{epilogue});

    #---------------
    # Beginning time
    #---------------
    if (defined $job->{begint})
    {
        my $begint = $job->{begint};
        $begint =~ s/[\-\s]//g;
        my @a = ($begint =~ /([\d\.]+)/g);

        if (scalar(@a) == 3)
        {
            print SH "#PBS -a $a[0]$a[1].$a[2]\n";
        }
        else
        {
            $begint = join('', @a);
            print SH "#PBS -a $begint\n";
        }
    }
        
    #----------------------
    # Job dependency option
    #----------------------
    if (defined $job->{depend})
    {
        my $depend = &_depend($job->{depend});
        print SH "#PBS -W depend=$depend\n";
    }
    print SH "\n";

    #--------------
    # Trace the job
    #--------------
    my $cmd = $job->{cmd};
    my $tracer = $job->{tracer};
    if ($tracer && $tracer ne 'off')
    {
        my $server;
        if (defined $self->{server})
        {
            $server = $self->{server};
        }
        else
        {
            $server = `qstat -Bf|head -1`;
            $server = substr($server, 8);
        }

        my ($tfile) = (defined $job->{tfile})? ($job->{tfile}):
            ($job->{script}.'.t$PBS_JOBID');
        &_trace($server, $tfile, $cmd);
    }
    else
    {
        #----------------
        # Execute command
        #----------------
        print SH "$cmd\n";
    }
    close(SH);

    return($file);
}
#-----------------------------------------------------------------


#------------------------------
# Count number of previous jobs
sub _numPrevJob
{
    my ($job) = @_;
    my $on = 0;
    if (defined $job->{prev})
    {
        foreach my $type (keys %{$job->{prev}})
        {
            if (ref($job->{prev}{$type}) eq 'ARRAY')
            {
                foreach my $jobTmp (@{$job->{prev}{$type}})
                {
                    my $prevcmd = $jobTmp->{cmd};
                    if (ref($prevcmd))
                    {
                        my $numCmd = scalar(@$prevcmd);
                        $on += $numCmd;
                    }
                    else
                    {
                        $on++;
                    }
                }
            }
            else
            {
                my $prevcmd = $job->{prev}{$type}{cmd};
                if (ref($prevcmd))
                {
                    my $numCmd = scalar(@$prevcmd);
                    $on += $numCmd;
                }
                else
                {
                    $on++;
                }
            }
        }
    }
    return($on);
}
#------------------------------


#----------------------
# Submit dependent jobs
# - called by qsub()
sub _qsubDepend
{
    my ($self, $job, $pbsid) = @_;

    my %type = (
        'prevstart' => 'before',
        'prevend'   => 'beforeany',
        'prevok'    => 'beforeok',
        'prevfail'  => 'beforenotok',
        'nextstart' => 'after',
        'nextend'   => 'afterany',
        'nextok'    => 'afterok',
        'nextfail'  => 'afternotok',
        );

    foreach my $order (qw(prev next))
    {
        foreach my $cond (qw(start end ok fail))
        {
            if (defined $job->{$order}{$cond})
            {
                my $type = $type{$order.$cond};
                if (ref($job->{$order}{$cond}) eq 'ARRAY')    # array of job obj
                {
                    foreach my $jobTmp (@{$job->{$order}{$cond}})
                    {
                        $$jobTmp{depend}{$type} = $pbsid;
                        &qsub($self, $jobTmp);
                    }
                }
                else
                {
                    my $jobTmp = $job->{$order}{$cond};
                    $$jobTmp{depend}{$type} = $pbsid;
                    &qsub($self, $jobTmp);
                }
            }
        }
    }
}
#----------------------


#------------------------
# Dispatch dependent jobs
# - called by dispatch()
sub _dphDepend
{
    my ($self, $job, $pbsid) = @_;

    my %type = (
        'prevstart' => 'before',
        'prevend'   => 'beforeany',
        'prevok'    => 'beforeok',
        'prevfail'  => 'beforenotok',
        'nextstart' => 'after',
        'nextend'   => 'afterany',
        'nextok'    => 'afterok',
        'nextfail'  => 'afternotok',
        );

    foreach my $order (qw(prev next))
    {
        foreach my $cond (qw(start end ok fail))
        {
            if (defined $job->{$order}{$cond})
            {
                my $type = $type{$order.$cond};
                if (ref($job->{$order}{$cond}) eq 'ARRAY')    # array of job obj
                {
                    foreach my $jobTmp (@{$job->{$order}{$cond}})
                    {
                        $$jobTmp{depend}{$type} = $pbsid;
                        &dispatch($self, $jobTmp);
                    }
                }
                else
                {
                    my $jobTmp = $job->{$order}{$cond};
                    $$jobTmp{depend}{$type} = $pbsid;
                    &dispatch($self, $jobTmp);
                }
            }
        }
    }
}
#------------------------


#-----------------------------------------------------
# Trace the job by recording the location of execution
# - called by genScript()
#
# <IN>
# $cmd -- command string
sub _trace
{
    my ($server, $tfile, $cmd) = @_;

    print SH "server=$server\n";
    print SH "tfile=$tfile\n";
    print SH 'tfile=${tfile/%.$server/}'."\n";

    # Get machine, start and finish time
    print SH 'echo MACHINES : > $tfile'."\n";
    print SH 'cat $PBS_NODEFILE >> $tfile'."\n";
    print SH 'echo "" >> $tfile'."\n";
    print SH 'start=`date +\'%F %T\'`'."\n";
    print SH 'echo "START   : $start" >> $tfile'."\n";
    print SH "\n$cmd\n\n";
    print SH 'finish=`date +\'%F %T\'`'."\n";
    print SH 'echo "FINISH  : $finish" >> $tfile'."\n";

    # Calculate the duration of the command
    print SH 'begin=`date +%s -d "$start"`'."\n";
    print SH 'end=`date +%s -d "$finish"`'."\n";
    print SH 'sec=`expr $end - $begin`'."\n";
    print SH 'if [ $sec -ge 60 ]'."\n";
    print SH 'then'."\n";
    print SH '    min=`expr $sec / 60`'."\n";
    print SH '    sec=`expr $sec % 60`'."\n\n";
    print SH '    if [ $min -ge 60 ]'."\n";
    print SH '    then'."\n";
    print SH '        hr=`expr $min / 60`'."\n";
    print SH '        min=`expr $min % 60`'."\n";
    print SH '        echo "RUNTIME : $hr hr $min min $sec sec" >> $tfile'."\n";
    print SH '    else'."\n";
    print SH '        echo "RUNTIME : $min min $sec sec" >> $tfile'."\n";
    print SH '    fi'."\n";
    print SH 'else'."\n";
    print SH '    echo "RUNTIME : $sec sec" >> $tfile'."\n";
    print SH 'fi'."\n";
}
#-----------------------------------------------------


#----------------------------------------------------------
# Construct node request string
# - called by genScript()
#
# <IN>
# $job -- job object
#
# <OUT>
# $str -- node request string
sub _nodes
{
    my ($job) = @_;
    $job->nodes('1') if (!defined $job->{nodes});
    my $type = ref($job->{nodes});

    #-------------------------------------------
    # String
    # Example:
    # (1) nodes => 2, ppn => 2
    # (2) nodes => "delta01+delta02", ppn => 2
    # (3) nodes => "delta01:ppn=2+delta02:ppn=1"
    #-------------------------------------------
    if ($type eq '')
    {
        if ($job->{nodes} =~ /^\d+$/)
        {
            my $str = "$job->{nodes}";
            $str .= ":ppn=$job->{ppn}" if (defined $job->{ppn});
            return($str);
        }
        else
        {
            if (defined $job->{ppn})
            {
                my @node = split(/\s*\+\s*/, $job->{nodes});
                my $str = join(":ppn=$job->{ppn}+", @node);
                $str .= ":ppn=$job->{ppn}";
                return($str);
            }
            return($job->{nodes});
        }
    }
    #-----------------------------------------------
    # Array
    # Example:
    # (1) nodes => [qw(delta01 delta02)], ppn => 2
    # (2) nodes => [qw(delta01:ppn=2 delta02:ppn=1)]
    #-----------------------------------------------
    elsif ($type eq 'ARRAY')
    {
        if (defined $job->{ppn})
        {
            my $str = join( ":ppn=$job->{ppn}+", @{$job->{nodes}} );
            $str .= ":ppn=$job->{ppn}";
            return($str);
        }
        return( join('+', @{$job->{nodes}}) );
    }
    #------------------------------------------
    # Hash
    # Example:
    # (1) nodes => {delta01 => 2, delta02 => 1}
    #------------------------------------------
    elsif ($type eq 'HASH')
    {
        my $str = '';
        foreach my $node (keys %{$job->{nodes}})
        {
            $str .= "$node:ppn=${$job->{nodes}}{$node}+";
        }
        chop($str);
        return($str);
    }
}
#----------------------------------------------------------


#----------------------------------------------------------
# Construct string for file staging (in and out)
# - called by genScript()
sub _stage
{
    my ($act, $file) = @_;
    my $type = ref($file);

    #-------------------------------------------
    # String
    # Example:
    # stagein => "to01.file@fromMachine:from01.file,".
    #            "to02.file@fromMachine:from02.file"
    # stageout => "from01.file@toMachine:to01.file,".
    #             "from02.file@toMachine:to02.file"
    #-------------------------------------------
    return($file) if ($type eq '');

    #-------------------------------------------
    # Array
    # Example:
    # stagein => ['to01.file@fromMachine:from01.file',
    #             'to02.file@fromMachine:from02.file']
    # stageout => ['from01.file@toMachine:to01.file',
    #              'from02.file@toMachine:to02.file']
    #-------------------------------------------
    return(join(',', @$file)) if ($type eq 'ARRAY');

    #-------------------------------------------
    # Hash
    # Example:
    # stagein => {'fromMachine:from01.file' => 'to01.file',
    #             'fromMachine:from02.file' => 'to02.file'}
    # stageout => {'from01.file' => 'toMachine:to01.file',
    #              'from02.file' => 'toMachine:to02.file'}
    #-------------------------------------------
    if ($type eq 'HASH')
    {
        if ($act eq 'in')
        {
            my @stages;
            foreach my $f (keys %$file)
            {
                push(@stages, "$$file{$f}".'@'."$f");
            }
            return(join(',', @stages));
        }
        elsif ($act eq 'out')
        {
            my @stages;
            foreach my $f (keys %$file)
            {
                push(@stages, "$f".'@'."$$file{$f}");
            }
            return(join(',', @stages));
        }
    }
}
#----------------------------------------------------------


#----------------------------------------------------------
# Construct the job dependency string
# - called by genScript()
#
# <IN>
# $arg -- hash reference of job dependency
#
# <OUT>
# $str -- job dependency string
sub _depend
{
    my ($arg) = @_;
    my $str = '';

    foreach my $type (keys %$arg)
    {
        $str .= ',' unless ($str eq '');
        my $joblist = join(':', @{$$arg{$type}});
        $str .= "$type:$joblist";
    }
    return($str);
}
#----------------------------------------------------------


#----------------------------------------------------------
# Construct the mail address list string
# - called by genScript()
#
# <IN>
# "abc@ABC.com, def@DEF.com" or
# [qw(abc@ABC.com def@DEF.com)]
#
# <OUT>
# abc@ABC.com,def@DEF.com
sub _mailList
{
    my ($arg) = @_;
    if (ref($arg) eq 'ARRAY')
    {
        return(join(',', @$arg));
    }
    else
    {
        $arg =~ s/,\s+/,/g;
        return($arg);
    }
}
#----------------------------------------------------------


#----------------------------------------------------------
# Construct the environment variable list string
# - called by genScript()
#
# <IN>
# ['A', 'B =b', {C => '', D => 'd'}],
#
# <OUT>
# A,B=b,c,D=d
sub _varList
{
    my ($arg) = @_;

    if (ref($arg) eq 'ARRAY')
    {
        my $str;
        foreach my $ele (@$arg)
        {
            $str .= ',' if (defined $str);
            if (ref($ele) eq 'HASH')
            {
                $str .= &_hashVar($ele);
            }
            else
            {
                $ele =~ s/\s*=\s*/=/;    # remove possible spaces around "="
                $str .= $ele;
            }
        }
        return($str);
    }
    elsif (ref($arg) eq 'HASH')
    {
        return(&_hashVar($arg));
    }
    else
    {
        my $str = $arg;
        $str =~ s/\s*=\s*/=/g;
        $str =~ s/\s*,\s+/,/g;
        return($str);
    }

    # Construct environment variable list string from hash
    sub _hashVar
    {
        my ($h) = @_;
        my $str;
        foreach my $key (keys %$h)
        {
            $str .= ',' if (defined $str);
            $str .= "$key";
            $str .= "=$$h{$key}" if ($$h{$key} ne '');
        }
        return($str);
    }
}
#----------------------------------------------------------


#################### PBS::Client::Job ####################

package PBS::Client::Job;
use strict;

#------------------------------------------------
# Job class
#------------------------------------------------

use Cwd;
use Carp;

#-------------------------
# Constructor method
#
# <IN>
# $class -- job object
# %hash --- argument hash
#
# <OUT>
# $self -- job object
sub new
{
    my ($class, %hash) = @_;

    #-------------
    # set defaults
    #-------------
    $hash{wd} = cwd if (!defined $hash{wd});
    $hash{script} = 'pbsjob.sh' if (!defined $hash{script});
    $hash{tracer} = 'off' if (!defined $hash{tracer});
    $hash{shell} = '/bin/sh' if (!defined $hash{shell});
    $hash{name} = $hash{script} if (!defined $hash{name});

    my $self = \%hash;
    return bless($self, $class);
}
#-------------------------


#--------------------------
# Generic attribute methods
sub AUTOLOAD
{
    my ($self, $key) = @_;
    my $attr = our $AUTOLOAD;
    $attr =~ s/.*:://;
    return if ($attr eq 'DESTROY');        # ignore destructor
    $self->{$attr} = $key if (defined $key);
    return($self->{$attr});
}
#--------------------------


#---------------------------------------
# Pack commands
#
# <IN>
# $self -- job object
# %args -- argument hash
#          -- numQ -- number of queues
#          -- cpq --- commands per queue
sub pack
{
    my ($self, %args) = @_;
    my $cmdlist = $self->{cmd};
    return if (ref($cmdlist) ne 'ARRAY');

    my @pack = ();
    my $jc = 0;        # job counter
    if (defined $args{numQ})
    {
        for (my $i = 0; $i < @$cmdlist; $i++)
        {
            if (ref($$cmdlist[$i]))
            {
                foreach my $cell (@{$$cmdlist[$i]})
                {
                    my $row = $jc % $args{numQ};
                    push(@{$pack[$row]}, $cell);
                    $jc++;
                }
            }
            else
            {
                my $row = $jc % $args{numQ};
                push(@{$pack[$row]}, $$cmdlist[$i]);
                $jc++;
            }
        }
    }
    elsif (defined $args{cpq})
    {
        for (my $i = 0; $i < @$cmdlist; $i++)
        {
            if (ref($$cmdlist[$i]))
            {
                foreach my $cell (@{$$cmdlist[$i]})
                {
                    my $row = int($jc / $args{cpq});
                    push(@{$pack[$row]}, $cell);
                    $jc++;
                }
            }
            else
            {
                my $row = int($jc / $args{cpq});
                push(@{$pack[$row]}, $$cmdlist[$i]);
                $jc++;
            }
        }
    }
    $self->cmd([@pack]);
}
#---------------------------------------


#-------------------------------
# Copy object using Data::Dumper
sub copy
{
    my ($self, $num) = @_;
    use Data::Dumper;
    if (!defined $num || $num == 1)
    {
        my $clone;
        eval(Data::Dumper->Dump([$self], ['clone']));
        return($clone);
    }

    my @clones = ();
    for (my $i = 0; $i < $num; $i++)
    {
        my $clone;
        eval(Data::Dumper->Dump([$self], ['clone']));
        push(@clones, $clone)
    }
    return(@clones);
}
#-------------------------------


__END__

=head1 NAME

PBS::Client - Perl interface to submit jobs to Portable Batch System (PBS).

=head1 SYNOPSIS

    # Load this module
    use PBS::Client;
    
    # Create a client object
    my $client = PBS::Client->new();
    
    # Specify the job
    my $job = PBS::Client::Job->new(
        queue => <job queue>,
        mem   => <memory requested>,
        .....
        cmd   => <command list in array reference>
    );
    
    # Optionally, re-organize the commands to a number of batched
    $job->pack(numQ => <number of batch>);
    
    # Submit the job
    $client->qsub($job);

=head1 DESCRIPTION

This module provides a Perl interface to submit jobs to the Portable Batch
System (PBS) server. PBS is a software allocating recources of a network to
batch jobs. This module lets you submit jobs on the fly.

To submit jobs by PBS::Client, you need to prepare two objects: the client
object and the job object. The client object connects to the server and submits
jobs (described by the job object) by the method C<qsub>.

The job object specifies various properties of a job (or a group of jobs).
Properties that can be specified includes job name, CPU time, memory, priority,
job inter-dependency and many others.

This module attempts to adopt the same philosophy of Perl, of which it tries
to understand what you want to do and gives you the least surprise. Therefore,
you usually can do the same thing with more than one way. This is also a
reason that makes this document lengthy.

=head1 SIMPLE USAGE

Three basic steps:

=over

=item 1. Create a client object, e.g.,

    my $client = PBS::Client->new();

=item 2. Create a job object and specify the commands to be submitted. E.g., to
submit jobs to get the current working directory and current date-time:

    my $job = PBS::Client::Job->new(cmd => ['pwd', 'date']);

=item 3. Use the C<qsub()> method of the client object to submit the jobs, e.g.,

    $client->qsub($job);

=back

There are other methods and options of the client object and job object. Most
of the options are optional. When omitted, default values would be used. The
only must option is C<cmd> which tells the client object what commands to be
submitted. 

=head1 CLIENT OBJECT METHODS

=head2 new()

    $pbs = PBS::Client->new(
        server => $server       # PBS server name (optional)
    );

Client object is created by the C<new> method. The name of the PBS server can
by optionally supplied. If it is omitted, the default server is assumed.

=head2 qsub()

Job (as a job object) is submitted to PBS by the method C<qub>.

    my $pbsid = $pbs->qsub($job_object);

An array reference of PBS job ID would be returned.

=head1 JOB OBJECT METHODS

=head2 new()

     $job = PBS::Client::Job->new(
         # Job declaration options
         wd        => $wd,              # working directory, default: cwd
         name      => $name,            # job name, default: pbsjob.sh
         script    => $script,          # job script name, default: pbsjob.sh
         shell     => $shell,           # shell path, default: /bin/sh
         account   => $account,         # account string
     
         # Resources options
         partition => $partition,       # partition
         queue     => $queue,           # queue
         begint    => $begint,          # beginning time
         host      => $host,            # host used to execute
         nodes     => $nodes,           # execution nodes, default: 1
         ppn       => $ppn,             # process per node
         pri       => $pri,             # priority
         nice      => $nice,            # nice value
         mem       => $mem,             # requested total memory
         pmem      => $pmem,            # requested per-process memory
         vmem      => $vmem,            # requested total virtual memory
         pvmem     => $pvmem,           # requested per-process virtual memory
         cput      => $cput,            # requested total CPU time
         pcput     => $pcput,           # requested per-process CPU time
         wallt     => $wallt,           # requested wall time
     
         # IO options
         stagein   => $stagein,         # files staged in
         stageout  => $stageout,        # files staged out
         ofile     => $ofile,           # standard output file
         efile     => $efile,           # standard error file
         maillist  => $mails,           # mail address list
         mailopt   => $options,         # mail options, combination of a, b, e
     
         # Command options
         vars      => {%name_values},   # name-value of env variables
         cmd       => [@commands],      # command to be submitted
         prev      => {                 # job before
                       ok    => $job1,  # successful job before this job
                       fail  => $job2,  # failed job before this job
                       start => $job3,  # started job before this job
                       end   => $job4,  # ended job before this job
                      },
         next      => {                 # job follows
                       ok    => $job5,  # next job after this job succeeded
                       fail  => $job6,  # next job after this job failed
                       start => $job7,  # next job after this job started
                       end   => $job8,  # next job after this job ended
                      },
     
         # Job tracer options
         tracer    => $on,              # job tracer, either on / off (default)
         tfile     => $tfile,           # tracer report file
     );

Two points may be noted:

=over

=item 1. Except C<cmd>, all attributes are optional.

=item 2. All attributes can also be modified by methods, e.g.,

    $job = PBS::Client::Job->new(cmd => [@commands]);

is equivalent to

    $job = PBS::Client::Job->new();
    $job->cmd([@commands]);

=back

=head3 Job Declaration Options

=head4 wd

Full path of the working directory, i.e. the directory where the command(s) is
executed. The default value is the current working directory.

=head4 name

Job name. It can have 15 or less characters. It cannot contain space and the
first character must be alphabetic. If not specified, it would follow the
script name.

=head4 script

Filename prefix of the job script to be generated. The PBS job ID would be
appended to the filename as the suffix.

Example: C<< script => test.sh >> would generate a job script like
F<test.sh.12345> if the job ID is '12345'.

The default value is C<pbsjob.sh>.

=head4 shell

Thsi option lets you to set the shell path. The default path is C</bin/sh>.

=head4 account

Account string. This is meaningful if you need to which account you are using
to submit the job.

=head3 Resources Options

=head4 partition

Partition name. This is meaningful only for the clusters with partitions. If it
is omitted, default value will be assumed.

=head4 queue

Queue of which jobs are submitted to. If omitted, default queue would be used.

=head4 begint (Experimental)

The date-time at which the job begins to queue. The format is either
"[[[[CC]YY]MM]DD]hhmm[.SS]" or "[[[[CC]YY-]MM-]DD] hh:mm[:SS]".

Example:

    $job->begint('200605231448.33');
    # or equilvalently
    $job->begint('2006-05-23 14:48:33');

This feature is in Experimental phase. It may not be supported in later
versions.

=head4 host

You can specify the host on which the job will be run.

=head4 nodes

Nodes used. It can be an integer (declaring number of nodes used), string
(declaring which nodes are used), array reference (declaring which nodes are
used), and hash reference (declaring which nodes, and how many processes of
each node are used).

Examples:

=over

=item * Integer

    nodes => 3

means that three nodes are used.

=item * String / array reference

    # string representation
    nodes => "node01 + node02"
    
    # array representation
    nodes => ["node01", "node02"]

means that nodes "node01" and "node02" are used.

=item * Hash reference

    nodes => {node01 => 2, node02 => 1}

means that "node01" is used with 2 processes, and "node02" with 1 processes.

=back

=head4 ppn

Maximum number of processes per node. The default value is 1.

=head4 pri

Priority of the job in queueing. The higher the priority is, the shorter is the
queueing time. Priority must be an integer between -1024 to +1023 inclusive.
The default value is 0.

=head4 nice

Nice value of the job during execution. It must be an integer between -20
(highest priority) to 19 (lowest). The default value is 10.

=head4 mem

Maximum physical memory used by all processes. Unit can be b (bytes), w
(words), kb, kw, mb, mw, gb or gw. If it is omitted, default value will be
used. Please see also L<pmem>, L<vmem> and L<pvmem>.

=head4 pmem

Maximum per-process physical memory. Unit can be b (bytes), w (words), kb, kw,
mb, mw, gb or gw. If it is omitted, default value will be used. Please see also
L<mem>, L<vmem> and L<pvmem>.

=head4 vmem

Maximum virtual memory used by all processes. Unit can be b (bytes), w (words),
kb, kw, mb, mw, gb or gw. If it is omitted, default value will be used. Please
see also L<mem>, L<pmem> and L<pvmem>.

=head4 pvmem

Maximum virtual memory per processes. Unit can be b (bytes), w (words), kb, kw,
mb, mw, gb or gw. If it is omitted, default value will be used. Please see also
L<mem>, L<pmem> and L<vmem>.

=head4 cput

Maximum amount of total CPU time used by all processes. Values are specified in
the form [[hours:]minutes:]seconds[.milliseconds].

Example:

    $job->cput('00:30:00');

refers to 30 minutes of CPU time. Please see also L<pcput> and L<wallt>.

=head4 pcput

Maximum amount of per-process CPU time. Values are specified in the form
[[hours:]minutes:]seconds[.milliseconds]. Please see also L<cput> and L<wallt>.

=head4 wallt

Maximum amount of wall time used. Values are specified in the form
[[hours:]minutes:]seconds[.milliseconds]. Please see also L<cput> and L<pcput>.

=head3 IO Options

=head4 stagein

Specify which files are need to stage (copy) in before the job starts. It may
be a string, array reference or hash reference. For example, to stage in
F<from01.file> and F<from02.file> in the remote host "fromMachine" and rename
F<to01.file> and F<to02.file> respectively, following three representation are
equilvalent:

=over

=item * String

    stagein => "to01.file@fromMachine:from01.file,".
               "to02.file@fromMachine:from02.file"

=item * Array

    stagein => ['to01.file@fromMachine:from01.file',
                'to02.file@fromMachine:from02.file']

=item * Hash

    stagein => {'fromMachine:from01.file' => 'to01.file',
                'fromMachine:from02.file' => 'to02.file'}

=back

=head4 stageout

Specify which files are need to stage (copy) out after the job finishs. Same as
C<stagein>, it may be string, array reference or hash reference.

Examples:

=over

=item * String

    stageout => "from01.file@toMachine:to01.file,".
                "from02.file@toMachine:to02.file"

=item * Array

    stageout => ['from01.file@toMachine:to01.file',
                 'from02.file@toMachine:to02.file']

=item * Hash

    stageout => {'from01.file' => 'toMachine:to01.file',
                 'from02.file' => 'toMachine:to02.file'}

=back

=head4 ofile

Path of the file for standard output. The default filename is like
F<jobName.o12345> if the job name is 'jobName' and its ID is '12345'. Please
see also L<efile>.

=head4 efile

Path of the file for standard error. The default filename is like
F<jobName.e12345> if the job name is 'jobName' and its ID is '12345'. Please
see also L<ofile>.

=head4 maillist

This option declares who (the email address list) will receive mail about the
job. The default is the job owner. The situation that the server will send
email is set by the C<mailopt> option shown below.

For more than one email addresses, C<maillist> can be either a comma separated
string or a array reference.

=head4 mailopt

This option declares under what situation will the server send email. It can be
any combination of C<a>, which indicates that mail will be sent if the job is
aborted, C<b>, indicating that mail will be sent if the job begins to run, and
C<e>, which indicates that mail will be sent if the job finishes. For example,

    mailopt => "b, e"
    # or lazily,
    mailopt => "be"

means that mail will be sent when the job begins to run and finishes.

The default is C<a>.

=head3 Command Options

=head4 vars

This option lets you expand the environment variables exported to the job. It
can be a string, array reference or hash reference.

Example: to export the following variables to the job: 

    A
    B = b
    C
    D = d

you may use one of the following ways:

=over

=item * String

    vars => "A, B=b, C, D=d",

=item * Array reference

    vars => ['A', 'B=b', 'C', 'D=d']

=item * Hash reference

    vars => {A => '', B => 'b', C => '', D => 'd'}

=item * Mixed

    vars => ['A', 'C', {B => 'b', D => 'd'}]

=back

=head4 cmd

Command(s) to be submitted. It can be an array (2D or 1D) reference or a
string. For 2D array reference, each row would be a separate job in PBS, while
different elements of the same row are commands which would be executed one by
one in the same job.  For 1D array, each element is a command which would be
submitted separately to PBS. If it is a string, it is assumed that the string
is the only one command which would be executed.

Examples:

=over

=item * 2D array reference

    cmd => [["./a1.out"],
            ["./a2.out" , "./a3.out"]]

means that C<a1.out> would be excuted as one PBS job, while C<a2.out> and
C<a3.out> would be excuted one by one in another job.

=item * 1D array reference

    cmd => ["./a1.out", "./a2.out"]

means that C<a1.out> would be executed as one PBS job and C<a2.out> would be
another. Therefore, this is equilvalent to

    cmd => [["./a1.out", "./a2.out"]]

=item * String

    cmd => "./a.out"

means that the command C<a.out> would be executed. Equilvalently, it can be

    cmd => [["./a.out"]]  # as a 2D array
    # or
    cmd => ["./a.out"]    # as a 1D array.

=back

=head4 prev

Hash reference which declares the job(s) executed beforehand. The hash can have
four possible keys: C<start>, C<end>, C<ok> and C<fail>. C<start> declares
job(s) which has started execution. C<end> declares job(s) which has already
ended. C<ok> declares job(s) which has finished successfully. C<fail> declares
job(s) which failed. Please see also L<next>.

Example:

    $job1->prev({ok => $job2, fail => $job3})

means that C<$job1> is executed only after C<$job2> exits normally and C<job3>
exits with error.

=head4 next

Hash reference which declares the job(s) executed later. The hash can have four
possible keys: C<start>, C<end>, C<ok> and C<fail>. C<start> declares job(s)
after started execution. C<end> declares job(s) after finished execution. C<ok>
declares job(s) after finished successfully. C<fail> declares job(s) after
failure. Please see also L<prev>.

Example:

    $job1->next({ok => $job2, fail => $job3})

means that C<$job2> would be executed after C<$job1> exits normally, and
otherwise C<job3> would be executed instead.

=head3 Job Tracer Options

=head4 tracer (Experimental)

Trace when and where the job was executing. It takes value of either on or off
(default). If it is turned on, an extra tracer report file would be generated.
It records when the job started, where it ran, when it finished and how long it
used.

This feature is in Experimental phase. It may not be supported in later
versions.

=head4 tfile (Experimental)

Path of the tracer report file. The default filename is like F<jobName.t12345>
if the job name is 'jobName' and its ID is '12345'. Please see also L<ofile>
and L<efile>.

This feature is in Experimental phase. It may not be supported in later
versions.

=head2 pbsid

Return the PBS job ID(s) of the job(s). It returns after the job(s) has
submitted to the PBS. The returned value is an integer if C<cmd> is a string.
If C<cmd> is an array reference, the reference of the array of ID will be
returned. For example,

    $pbsid = $job->pbsid;

=head2 pack()

C<pack> is used to rearrange the commands among different queues (PBS jobs).
Two options, which are C<numQ> and C<cpq> can be set. C<numQ> specifies number
of jobs that the commands will be distributed. For example,

    $job->pack(numQ => 8);

distributes the commands among 8 jobs. On the other hand, the C<cpq>
(abbreviation of B<c>ommand B<p>er B<q>ueue) option rearranges the commands
such that each job would have specified commands. For example,

    $job->pack(cpq => 8);

packs the commands such that each job would have 8 commands, until no command
left.

=head2 copy()

Job objects can be copied by the C<copy> method:

    my $new_job = $old_job->copy;

The new job object (C<$new_job>) is identical to, but independent of the
original job object (C<$old_job>).

C<copy> can also specify number of copies to be generated. For example,

    my @copies = $old_job->copy(3);

makes three identical copies.

Hence, the following two statements are the same:

    my $new_job = $old_job->copy;
    my ($new_job) = $old_job->copy(1);

=head1 SCENARIOS

=over

=item 1. Submit a Single Command

You want to run C<a.out> of current working directory in the default queue:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        cmd   => './a.out',
    );

=item 2. Submit a List of Commands

You need to submit a list of commands to PBS. They are stored in the Perl array
C<@jobs>. You want to execute them one by one in a single CPU:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        cmd => [\@jobs],
    );
    $pbs->qsub($job);

=item 3. Submit Multiple Lists

You have 3 groups of commands, stored in C<@jobs_a>, C<@jobs_b>, C<@jobs_c>.
You want to execute each group in different CPU:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        cmd => [
                \@jobs_a,
                \@jobs_b,
                \@jobs_c,
               ],
    );
    $pbs->qsub($job);

=item 4. Rearrange Commands (Specifying Number of Queues)

You have 3 groups of commands, stored in C<@jobs_a>, C<@jobs_b>, C<@jobs_c>.
You want to re-organize them to 4 batches:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        cmd => [
                \@jobs_a,
                \@jobs_b,
                \@jobs_c,
               ],
    );
    $job->pack(numQ => 4);
    $pbs->qsub($job);

=item 5. Rearrange Commands (Specifying Commands Per Queue)

You have 3 batches of commands, stored in C<@jobs_a>, C<@jobs_b>, C<@jobs_c>.
You want to re-organize them such that each batch has 4 commands:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        cmd => [
                \@jobs_a,
                \@jobs_b,
                \@jobs_c,
               ],
    );
    $job->pack(cpq => 4);
    $pbs->qsub($job);

=item 6. Customize resource

You want to customize the requested resources rather than using the default
ones:

    use PBS::Client;
    my $pbs = PBS::Client->new;
    
    my $job = PBS::Client::Job->new(
        account   => <account name>,
        partition => <partition name>,
        queue     => <queue name>,
        wd        => <working directory of the commands>,
        name      => <job name>,
        script    => <name of the generated script>,
        pri       => <priority>,
        mem       => <memory>,
        cput      => <maximum CPU time>,
        wallt     => <maximum wall clock time>,
        prologue  => <prologue script>,
        epilogue  => <epilogue script>,
        cmd       => <commands to be submitted>,
    );
    $pbs->qsub($job);

=item 7. Job dependency

You want to run C<a1.out>. Then run C<a2.out> if C<a1.out> finished
successfully; otherwise run C<a3.out> and C<a4.out>.

    use PBS::Client;
    my $pbs = PBS::Client->new;
    my $job1 = PBS::Client::Job->new(cmd => "./a1.out");
    my $job2 = PBS::Client::Job->new(cmd => "./a2.out");
    my $job3 = PBS::Client::Job->new(cmd => ["./a3.out", "./a4.out"]);
    
    $job1->next({ok => $job2, fail => $job3});
    $pbs->qsub($job1);

=back

=head1 SCRIPT "RUN"

If you want to execute a single command, you need not write script.  The
simplest way is to use the script F<run> in this package. For example,

    run "./a.out --debug > a.dat"

would submit the job executing the command "a.out" with option "--debug", and
redirect the output to the file "a.dat".

The options of the job object, such as the resource requested can be edited by

    run -e

The more detail manual can be viewed by

    run -m

=head1 REQUIREMENTS

L<Data::Dumper>, L<File::Temp>

=head1 TEST

This module has only been tested with OpenPBS in Linux. However, it was written
to fit in as many Unix-like OS with PBS installed as possible.

=head1 BUGS AND LIMITATIONS

=over

=item 1. This module requires the PBS command line tools, especially C<qsub>
and C<qstat>.

=item 2. This module requires that all nodes can execute Bourne shell scripts,
and that the shell path are the same.

=item 3. Jobs with inter-dependency cannot be submitted to the non-default
server. This limitation will be removed soon, hopefully.

=back

Please email to kwmak@cpan.org for bug report or other suggestions.

=head1 SEE ALSO

PBS offical website http://www.openpbs.com,

L<PBS>

=head1 AUTHOR(S)

Ka-Wai Mak <kwmak@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2007, 2010-2011 Ka-Wai Mak. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
