################################################################################
#
# $Id: Family.pm 292 2010-03-24 03:43:40Z aijaz $
#
################################################################################


=head1 NAME

TaskForest::Family - A collection of jobs

=head1 SYNOPSIS

 use TaskForest::Family;

 my $family = TaskForest::Family->new(name => 'Foo');
 # the associated job dependencies are read within new();

 $family->getCurrent();
 # get the status of all jobs, what's failed, etc.

 $family->cycle();
 # runs any jobs that are ready to be run

 $family->display();
 # print to stdout a list of all jobs in the family
 # and their statuses

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

A family is a group of jobs that share the following
characteristics:

=over

=item *

They all start on or after a common time known as the family start time.

=item *

They run only on the days specified in the family file.

=item *

They can be dependent on each other.  These dependencies are
represented by the location of jobs with respect to each other in
the family file.

=back

For more information about jobs, please look at the documentation for
the TaskForest class.

=head1 ATTRIBUTES

The following are attributes of objects of the family class:

=over 2

=item name

The name is the same as the name of the config file that contains the
job dependency information.

=item start

The family start time in 'HH:MM' format using the 24-hour clock. e.g.:
'17:30' for 5:30 p.m.

=item tz

The time zone with which the family start time is to be interpreted.

=item days

An array reference of days of the week on which this family's jobs may
run.  Valid days are 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' and  'Sun'.
Anything else will be ignored.

=item options

A hash reference that contains the values of the options retrieved from
the command line or the environment,

=item jobs

A hash reference of all the jobs that are members of this family.  The
keys of this hash are the names of the jobs.  The names of the jobs are in
the family configuration file and they're the same as the filenames of the
jobs on disk.

=item current

A boolean that is set to true after all the details of the family's jobs
are read from status files in the log directory.  This boolean is set to
false when an attempt is made to run any jobs, and when the family config
file is first read (before getCurrent() is called).

=item ready_jobs

A temporary hash reference of jobs that are ready to be run - jobs whose
dependencies have been met.

=item dependencies

A hash reference of dependencies of all jobs (things that the jobs depend
ON).  The keys of this hash are the job names.  The values are array
references.  Each array reference can contain 1 or more references to
objects of type TaskForest::Job or TaskForest::TimeDependency.

All jobs have at least one dependency - a TimeDependency that's set to the
start time of the Family.  In other words, after the start time of the
Family passes, the check() method of the TimeDependency will return 1.
Before that, it will return 0.

=item time_dependencies

For convenience, all time dependencies encountered in this family
(including that of the family start time) are saved in this array
reference.  The other types of time dependencies are those that apply to
individual jobs.

=item family_time_dependency

This is the TaskForest::TimeDependency that refers to the family start
time.

=item year, mon, mday and wday

These attributes refer to the current day.  They're saved within the
Family object so that we don't have to call localtime over and over again.
I really should have this cached this somewhere else.  Oh, well.

=item filehandle

The readFromFile function was *really* long, so I refactored it into
smaller functions.  Since at least two of the functions read from the
file, I saved the file handle within the object.

=item current_dependency, last_dependency

These are temporary attributes that builds dependency lists while parsing
the file.  

=back    

=head1 METHODS

=cut    

package TaskForest::Family;

use strict;
use warnings;
use TaskForest::Job qw ();
use Data::Dumper;
use TaskForest::TimeDependency;
use TaskForest::Options;
use TaskForest::LogDir;
use English '-no_match_vars';
use FileHandle;
use Carp;
use Time::Local;
use Fcntl qw(:DEFAULT :flock);
use TaskForest::LocalTime;
use TaskForest::Calendar;


BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.32';
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item new()

 Usage     : my $family = TaskForest::Family->new();
 Purpose   : The Family constructor is passed the family name.  It
             uses this name along with the location of the family
             directory to find the family configuration file and
             reads the file.  The family object is configured with
             the data read in from the file.
 Returns   : Self
 Argument  : A hash that has the properties of he family.  Of these,
             the only required one is the 'name' property.
 Throws    : "No family name specified" if the name property is
              blank.  

=back

=cut

# ------------------------------------------------------------------------------
sub new {
    my $arg = shift;
    my $class = (ref $arg) || $arg;

    my $self = {
        name   => '',
        start  => '',
        tz     => 'America/Chicago',        # default America/Chicago
        days   => {},
    };

    my %args = @_;
    
    foreach my $key (keys %args) {
        $self->{$key} = $args{$key};
    }

    croak "No family name specified" unless $self->{name};
    bless $self, $class;

    $self->{options} = &TaskForest::Options::getOptions();
    
    $self->readFromFile();

    return $self;
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item display()

 Usage     : $family->display()
 Purpose   : This method displays the status of all jobs in this family.
             families that are scheduled to run today.
 Returns   : Nothing
 Argument  : A hash that will contain a list of jobs.  This hash can be
             passed to other jobs as well.  
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub display {
    my ($self, $display_hash) = @_;

    foreach my $job_name (sort
                          { $self->{jobs}->{$a}->{start} cmp $self->{jobs}->{$b}->{start} }
                          (keys (%{$self->{jobs}}))) {
        
        my $job_hash = { family_name => $self->{name} };
        my $job      = $self->{jobs}->{$job_name};
        foreach my $k (keys %$job) { $job_hash->{$k} = $job->{$k}; }
        push (@{$display_hash->{all_jobs}}, $job_hash);
        push (@{$display_hash->{$job_hash->{status}}}, $job_hash);
    }

}




# ------------------------------------------------------------------------------
=pod

=over 4

=item getCurrent()

 Usage     : $family->getCurrent()
 Purpose   : This method reads all the semaphore files in the log
             directory and gets the current status of the entire
             family.  Each run job can have succeeded or failed.  As
             a result of this, other jobs may be Ready to be run.  If
             a job's dependencies have not yet been met, it is said
             to be in the Waiting state.  Once a family is current,
             the only thing that makes it 'uncurrent' is if any jobs
             are run, or if its configuration file changes.
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub getCurrent {
    my $self = shift;
    my $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $self->{tz});


    if ($self->{current}) {
        # nothing to do, really
        return;
    }

    # now get the status of all the jobs from external families
    $self->getForeignStatus($log_dir);

    # Get the status of all jobs, depending on the presence of job
    # semaphore files
    # 
    $self->updateJobStatuses();

    # Check to see if any of the time dependencies in this family have
    # been met.  A time dependency has been met if 'now' >= the time
    # dependency.
    #
    $self->checkAllTimeDependencies();

    # Get a list of all jobs whose status is 'Waiting'
    # Some of these may be running, and some may be ready
    #
    my $waiting_jobs = $self->getAllWaitingJobs();
    print "waiting: ", Dumper($waiting_jobs) if $self->{options}->{verbose};

    # Construct a list of all ready jobs - these are jobs for which
    # all dependencies have been met
    #
    $self->{ready_jobs} = {};
    $self->{token_jobs} = {};
    foreach my $job (values %$waiting_jobs) {
        my $started_semaphore = "$log_dir/$self->{name}.$job->{name}.started";
        #print "Looking for $started_semaphore\n";
        if (-e $started_semaphore) { # already running
            #open (F, $started_semaphore) || croak "Can't open file $started_semaphore";
            #$_ = <F>;
            #close F;
            #if (/(\d\d):(\d\d)/) {
            #    $job->{actual_start} ="$1:$2";
            #}
            $job->{status} = 'Running';
            $job->{stop} = '--:--';
            $job->{rc} = '-';
            my $pid_file = "$log_dir/$self->{name}.$job->{name}.pid";
            open (F, $pid_file) || croak "Can't open file $pid_file";
            while(<F>) {
                #print "  Looking at: $_";
                if (/^pid: (\d+)/) {
                    $job->{pid} ="$1";
                }
                elsif (/^actual_start: (\d+)/) {
                    $job->{actual_start} = $1;
                }
                elsif (/^unique_id: (\S+)/) {
                    $job->{unique_id} = $1;
                }
            }
            close F;
            next;
        }
        # dependencies for each job
        #
        my $dependencies = $self->{dependencies}->{$job->{name}};
        my $ready = 1;
        my $hold  = 0;

        my $hold_file = "$log_dir/$self->{name}.$job->{name}.hold";
        if (-e $hold_file) {
            $hold = 1;
            $job->{status} = 'Hold';
            $job->{is_hold} = 1;
        }
        
        # Don't bother checking for dependencies if on hold.  Always set ready to 0;
        if ($hold) {
            $ready = 0;
        }
        else {
            foreach my $dep (@$dependencies) {
                if ($dep->check($self->{foreign_status}) == 0) {
                    $ready = 0;
                    last;
                }
            }
        }
        
        # A release file does not override a hold file.
        my $release_file = "$log_dir/$self->{name}.$job->{name}.release";
        if (-e $release_file && ($hold == 0) ) {
            $ready = 1;

            # We cannot rely on the run wrapper to delete the release
            # file.  That's not its job. runReadyJobs has to do it.
        }

        

        if ($ready) {
            # set the status of the job to be ready
            if ($job->{tokens}  && @{$job->{tokens}}) {
                # token_jobs is a list of all jobs that have one more tokens
                $self->{token_jobs}->{$job->{name}} = $job;
                $job->{status} = 'TokenWait';
            }
            else {
                $self->{ready_jobs}->{$job->{name}} = $job;
                $job->{status} = 'Ready';
            }
        }
    }

    $self->{current} = 1;
    print "ready: ", Dumper($self->{ready_jobs}) if $self->{options}->{verbose};
}


sub getForeignStatus {
    my ($self, $log_dir) = @_;
    $self->{foreign_status} = {};
    foreach my $family_name (sort keys %{$self->{families}}) {
        my $glob_string = "$log_dir/$family_name.*.0";  # TODO: Want this to stay $self->{name}, so create a new type of dep.
        my @files = glob($glob_string);
        foreach my $file (@files) {
            my @components = split(/\./, $file);
            $self->{foreign_status}->{$components[-2]} = 1;
        }
    }
}

        

# ------------------------------------------------------------------------------
=pod

=over 4

=item cycle()

 Usage     : $family->cycle()
 Purpose   : This is the main method that is invoked once in every
             loop, to run any jobs that are in a Ready state.  It
             gets the current status of the family and runs any jobs
             that are in the Ready state.
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub cycle {
    my $self = shift;

    $self->getCurrent();
    $self->runReadyJobs();
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item updateJobStatuses()

 Usage     : $family->updateJobStatuses()
 Purpose   : This method looks at all the semaphore files in the
             current day's log directory and updates job statuses
             based on those semaphore files. 
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub updateJobStatuses {
    my $self = shift;

    my $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $self->{tz});

    # keep in mind that semaphore files are in the form F.J.[01] where
    # F is the family name, J is a job name and 0 means success, and 1
    # failure
    #

    # TODO: get a list of all famaily names in jobs, and append results of glob to files
    
    my $glob_string = "$log_dir/$self->{name}.*.[01]";  # TODO: Want this to stay $self->{name}, so create a new type of dep.
                                                        # object - an external dep object

    my @files = glob($glob_string);
    my %valid_fields = (
        actual_start => 1,
        pid          => 1,
        stop         => 1,
        rc           => 1,
        unique_id    => 1,
        );
    

    foreach my $file (sort @files) { # the sort ensures that 1 overrides 0
        my ($job_name, $status) = $file =~ /$log_dir\/$self->{name}\.([^\.]+)\.([01])/;
        my ($orig, $actual_name);
        
        if ($job_name =~ /(^[^\-]+)--Orig/) {
            $orig = 1;
            $actual_name = $1;
            next unless defined $self->{jobs}->{$actual_name};  # not defined if job is no longer in family, but ran ealier.
            $self->{jobs}->{$job_name} = TaskForest::Job->new('name' => $job_name);
        }
        else {
            next unless defined $self->{jobs}->{$job_name};  # not defined if job is no longer in family, but ran ealier.
        }

        # when a job is rerun the the job name in the job file has --Orig_n-- appended to it
        
        # when a job is marked successful (or failed) only the file
        # name is changed to *.1 (or *.0).  The return code is not to
        # be changed 
        if ($status == 1) {
            $self->{jobs}->{$job_name}->{status} = 'Failure';
        }
        else {
            $self->{jobs}->{$job_name}->{status} = 'Success';
        }
        # read the return code
        #
        open(F, $file) || croak "cannot open $file to read rc";
        $_ = <F>;
        chomp;
        $self->{jobs}->{$job_name}->{rc} = $_;
        close F;

        # read the pid file
        substr($file, -1, 1) = 'pid';
        open(F, $file) || croak "cannot open $file to read job data";
        while (<F>) { 
            chomp;
            my ($k, $v) = /([^:]+): (.*)/;
            $v =~ s/[^a-z0-9_ ,.\-]/_/ig;
            if ($valid_fields{$k}) {
                $self->{jobs}->{$job_name}->{$k} = $v;
            }
        }
        close F;
        
        if ($orig) {
            $self->{jobs}->{$job_name}->{start} = $self->{jobs}->{$actual_name}->{start};
            $self->{jobs}->{$job_name}->{tz}    = $self->{jobs}->{$actual_name}->{tz};
        }
    }
}
        
        

# ------------------------------------------------------------------------------
=pod

=over 4

=item runReadyJobs()

 Usage     : $family->runReadyJobs()
 Purpose   : This method uses the fork and exec model to run all jobs
             currently in the Ready state.  The script that is
             actually exec'ed is the run wrapper.  The wrapper takes
             a whole bunch of arguments, some of which can be derived
             by others.  The intent is to make it flexible and make
             it easy for others to write custom wrappers.  The code
             that's executed in the child process before the exec is
             rather paranoid and is taken from perldoc perlsec.
 Returns   : Nothing
 Argument  : None
 Throws    : "Can't drop privileges" if the userids cannot be
             changed

=back

=cut

# ------------------------------------------------------------------------------
sub runReadyJobs {
    my $self = shift;
    $self->{current} = 0; # no longer current.  A reread of log dirs is necessary
    my $wrapper = $self->{options}->{run_wrapper};
    my $log_dir = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $self->{tz});

    #print Dumper($self);
    $self->convertTokenWaitToReady();  # $self has just been made current
    #print Dumper($self);

    foreach my $job (values %{$self->{ready_jobs}}) { 
        my $pid;
        if ($pid = fork) {
            # parent
            print "Forked child process $job->{name} $pid\n";
            $job->{status} = 'Running';
            $self->writeSemaphoreFile("$log_dir/$self->{name}.$job->{name}.started", sprintf("%02d:%02d\n", $self->{hour}, $self->{min}));

            # you only get to release a job's dependencies once per
            # cycle.  If the job had run because its dependencies were
            # released, remove the release-dependency directive
            #
            my $release_file = "$log_dir/$self->{name}.$job->{name}.release";
            if (-e $release_file) {
                my $ok = unlink $release_file;
                if (!$ok) {
                    die ("Couldn't unlink the release_file directive - $release_file");
                }
            }
        }
        else {
            #child - this code comes from perldoc perlsec
            croak "cannot fork: $!" unless defined $pid;

            my @temp     = ($EUID, $EGID);
            my $orig_uid = $UID;
            my $orig_gid = $GID;
            $EUID = $UID;
            $EGID = $GID;
            
            # Drop privileges
            #
            $UID  = $orig_uid;
            $GID  = $orig_gid;
            
            # Make sure privs are really gone
            #
            ($EUID, $EGID) = @temp;
            croak "Can't drop privileges" unless $UID == $EUID  && $GID eq $EGID;
            $ENV{PATH} = "/bin:/usr/bin"; # Minimal PATH.
            $ENV{CDPATH} = ""; # We don't need this.
            
            # Consider sanitizing the environment even more.
            
            my $job_file_name = $job->{name};
            $job_file_name =~ s/--Repeat.*//;
            
            # generate unique run_id
            #
            my $time = time();
            my $run_id = "$$.$time";

            $ENV{TASKFOREST_FAMILY_NAME}            = $self->{name};
            $ENV{TASKFOREST_JOB_NAME}               = $job->{name};
            $ENV{TASKFOREST_JOB_FILE_NAME}          = $job_file_name;
            $ENV{TASKFOREST_LOG_DIR}                = $log_dir;
            $ENV{TASKFOREST_JOB_DIR}                = $self->{options}->{job_dir};
            $ENV{TASKFOREST_PID_FILE}               = "$log_dir/$self->{name}.$job->{name}.pid";
            $ENV{TASKFOREST_SUCCESS_FILE}           = "$log_dir/$self->{name}.$job->{name}.0";
            $ENV{TASKFOREST_FAILURE_FILE}           = "$log_dir/$self->{name}.$job->{name}.1";
            $ENV{TASKFOREST_UNIQUE_ID}              = $job->{unique_id};
            $ENV{TASKFOREST_NUM_RETRIES}            = defOr($job->{num_retries}, 0);
            $ENV{TASKFOREST_RETRY_SLEEP}            = defOr($job->{retry_sleep}, 0);
            $ENV{TASKFOREST_EMAIL}                  = defOr($job->{email}, "");
            $ENV{TASKFOREST_RETRY_EMAIL}            = defOr($job->{retry_email}, "");
            $ENV{TASKFOREST_NO_RETRY_EMAIL}         = defOr($job->{no_retry_email}, "");
            $ENV{TASKFOREST_INSTRUCTIONS_DIR}       = defOr($job->{instructions_dir}, "");
            $ENV{TASKFOREST_SMTP_SERVER}            = defOr($self->{options}->{smtp_server}, "");
            $ENV{TASKFOREST_SMTP_PORT}              = defOr($self->{options}->{smtp_port}, 0);
            $ENV{TASKFOREST_SMTP_SENDER}            = defOr($self->{options}->{smtp_sender}, "");
            $ENV{TASKFOREST_MAIL_FROM}              = defOr($self->{options}->{mail_from}, "");
            $ENV{TASKFOREST_MAIL_REPLY_TO}          = defOr($self->{options}->{mail_reply_to}, "");
            $ENV{TASKFOREST_MAIL_RETURN_PATH}       = defOr($self->{options}->{mail_return_path}, "");
            $ENV{TASKFOREST_SMTP_TIMEOUT}           = defOr($self->{options}->{smtp_timeout}, 0);
            $ENV{TASKFOREST_RETRY_SUCCESS_EMAIL}    = defOr($job->{retry_success_email}, "");
            $ENV{TASKFOREST_NO_RETRY_SUCCESS_EMAIL} = defOr($job->{no_retry_success_email}, "");
            
            exec("$wrapper",
                ) or croak "Can't exec: $!\n";
        }
    }
        
}

    

# ------------------------------------------------------------------------------
=pod

=over 4

=item checkAllTimeDependencies()

 Usage     : $family->checkAllTimeDependencies()
 Purpose   : Runs td->check() on all time dependencies, to see
             whether they have been met or not
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub checkAllTimeDependencies {
    my $self = shift;

    foreach my $td (@{$self->{time_dependencies}}) {
        $td->check();
    }
}

# ------------------------------------------------------------------------------
=pod

=over 4

=item getAllWaitingJobs()

 Usage     : $family->getAllWaitingJobs()
 Purpose   : This method gets a hash of all jobs that are currently
             in the Waiting state
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub getAllWaitingJobs {
    my $self = shift;

    my %waiting = map { $_->{name} => $_ } grep {$_->{status} eq 'Waiting'} values(%{$self->{jobs}});

    return \%waiting;
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item readFromFile()

 Usage     : $family->readFromFile
 Purpose   : This is the most crucial method of the application.  It
             reads the Family configuration file and constructs a
             data structure that represents all the configuration
             parameters of the family.
 Returns   : Nothing
 Argument  : None
 Throws    : "Can't read dir/file" if the config file cannot be read
             "No start time specified for Family",
             "No time zone specified for Family",
             "No run days specified for Family",
                if any of the 3 required headers are not present in
                the file
             Generic croak if the data cannot be extracted after an
             eval.

=back

=cut

# ------------------------------------------------------------------------------
sub readFromFile {
    my $self = shift;

    $self->_initializeDataStructures();

    my $file = $self->{name};
    my $dir = $self->{options}->{family_dir};
    $self->{file_handle} = new FileHandle;
    $self->{file_handle}->open("<$dir/$file") || croak "cant read $dir/$file";

    my $ok_to_run = $self->_parseHeaderLine();
    return unless $ok_to_run;
    

    my $sections = $self->_getSections();     # get concurrent sections
    return unless @$sections;                 # the file is either blank, or does not need to run today

    my @bad_lines = ();
    foreach my $section (@$sections) {
        my @lines = split(/\n/, $section);    # lines in the section
        
        # Create a one-element array of dependencies.  This is the
        # default dependency list for all jobs as they're first
        # encountered. 
        #
        $self->{last_dependency} = [ $self->{family_time_dependency} ];

        # list of lines that failed to parse
        my ($parsed_ok, $parse_error);
        my $first_line = 1;
        foreach my $line (@lines) {
            ($parsed_ok, $parse_error) = $self->_parseLine($line, $first_line);
            if (! $parsed_ok) {
                push(@bad_lines, "$line --- $parse_error");
            }
            $first_line = 0;
        }
    }
    
    if (@bad_lines) {
        die ("Family '$self->{name}' has unparseable lines:\n  ", join("  \n", @bad_lines), "\n");
    }

}


# ------------------------------------------------------------------------------
=pod

=over 4

=item okToRunToday()

 Usage     : $family->okToRunToday
 Purpose   : This method checks whether today is in the list of days
             of the week that this family is eligible to run
 Returns   : 1 if it is, 0 if it's not.
 Argument  : $wday - the day of the week today
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub okToRunToday {
    my ($self, $wday) = @_;

    my @days = qw (Sun Mon Tue Wed Thu Fri Sat Sun);
    my $today = $days[$wday];

    if ($self->{days}->{$today}) {
        return 1;
    }
    else {
        return 0;
    }
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item _initializeDataStrauctures()

 Usage     : $self->_intializeDataStructures
 Purpose   : Used in readFrom file, before a file is opened for reading
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _initializeDataStructures {
    my $self = shift;
    
    $self->{dependencies} = {};
    $self->{jobs} = {};
    $self->{time_dependencies} = [];

    # once you reread a family's config file, it is no longer current
    #
    $self->{current} = 0;

    # get current time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::lt();
    ($self->{wday}, $self->{hour}, $self->{min}) = ($wday, $hour, $min);

    
}



# ------------------------------------------------------------------------------
=pod

=over 4

=item _getSections()

 Usage     : $self->_getSections
 Purpose   : Read concurrent sections from the family file 
 Returns   : A list of sections, or () if the file is empty
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _getSections {
    my $self = shift;
    my $fh = $self->{file_handle};   
   
    # PARSE THE FILE HERE
    my @sections = split(/^ *-+ *\n/m,             # split on a line of dashes
                         (join '',                 # convert back to a string
                          grep(/\S/,               # get rid of blank lines
                               (map {s/\#.*//;     # get rid of comments
                                     s/\r//g;      #  and line-feeds
                                     $_; }         
                                $fh->getlines())))); # all lines as a list
    
    $fh->close();

    return \@sections;
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item _parseHeaderLine()

 Usage     : $self->_parseHeaderLine()
 Purpose   : Read the first non-empty line from the family file.
             If this family is not scheduled to run today, then just
             close the file and return 0.  This means that you
             could change the days in the header file in the middle
             of the day, and add today to the list of valid
             days. This would cause the family to now become
             eligible to run today, when earlier in the  day it was
             not. 
 Returns   : 1 if the family is to run today, 0 otherwise.
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _parseHeaderLine {
    my $self = shift;
    my $fh = $self->{file_handle};
    while (<$fh>) {
        chomp;
        last if /\S/;  # get first non-blank line
    }

    s/\s//g;           # get rid of spaces

    # make sure all the data we expect in the header is available
    #
    my $args = '';
    my $file = $self->{name};

    # using this parsing means that extra junk in the header line is ignored - makes the parsing more
    # resistant to errors
    #
    if (/(start=>['"]\d+:\d+['"])/)                    { $args .= "$1,"; } else { croak "No start time specified for Family $file"; }
    if (/(days=>['"][a-zA-Z0-9,]+['"])/)               { $args .= "$1,"; } 
    if (/(tz=>['"][a-zA-Z0-9\/\_]+['"])/)              { $args .= "$1,"; } else { croak "No time zone specified for Family $file"; }
    if (/cal[ae]nd[ae]r=>(['"][a-zA-Z0-9_]+['"])/)     { $args .= "calendar=>$1,"; } 
             
    my %args = eval($args);

    $self->{start} = $args{start};          # set the start time

    if ($args{days}) {
        my @days = split(/,/, $args{days});
        
        my %valid_days = (Mon=>1, Tue=>1, Wed=>1, Thu=>1, Fri=>1, Sat=>1, Sun=>1);
        foreach my $day (@days) {
            if (!($valid_days{$day})) {
                croak "Day $day is not a valid day.  Valid days are: Mon, Tue, Wed, Thu, Fri, Sat and Sun";
            }
            $self->{days}->{$day} = 1;          # valid to run on these days
        }

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::ft($args{tz});
        ($self->{wday}, $self->{hour}, $self->{min}) = ($wday, $hour, $min);
        
        if ($self->okToRunToday($self->{wday}) == 0) {  # nothing to do
            $fh->close();
            return 0;
        }
    }
    elsif($args{calendar}) {
        # make sure calendar exists
        my $calendar_name = $args{calendar};
        my $calendar_file = "$self->{options}->{calendar_dir}/$calendar_name";
        unless (-e $calendar_file) {  
            print "Calendar $calendar_file does not exist\n";
            return 0;
        }


        my @rules;
        if (open (C, $calendar_file)) {
            @rules = <C>;
            close C;
        }
        else {
            croak "Calendar $calendar_file cannot be opened";
        }
        
        #print "Calendar $calendar_name exists with tz= $args{tz}\n";
        #print Dumper($self->{options}->{calendar}->{$calendar_name}->{rules});
        # calendar exists - use it.
        if (&TaskForest::Calendar::canRunToday({ rules => \@rules, tz => $args{tz}}) ne '+') {
            $fh->close();
            return 0;
        }
    }
    else {
        croak "Neither 'days' nor 'calendar' is specified";
    }

    # create main dependency - every job has at least one dependency:
    # a time dependency on the start time of the family.   
    #
    $self->{tz} = $args{tz};
    my %td_args = ( start => $self->{start} );
    $td_args{tz} = $self->{tz};                  # for now, this is a required field
    $self->{family_time_dependency} = TaskForest::TimeDependency->new(%td_args);
    push (@{$self->{time_dependencies}}, $self->{family_time_dependency});

    return 1;
}

# ------------------------------------------------------------------------------
=pod

=over 4

=item _parseLine()

 Usage     : $self->_parseLine($line)
 Purpose   : Get a list of all jobs on the line and parse them,
             creating the data structure.
             As we process each line, we add to each job's
             dependencies the dependencies in
             $self->{last_dependency}.  We also add each job to the
             list of 'current' dependencies.  When we're done parsing
             the line, we set 'last' to 'current', for the benefit of
             the next line.
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _parseLine {
    my ($self, $line, $first_line) = @_;

    $self->{current_dependency} = [];
    $line =~ s/\s//g;                    # get rid of spaces

    my @jobs;

    # make sure that the line looks like this:
    # ([a-z0-9_]+\([^\)]*\) *)*
    if ($first_line) { 
        if ($line =~ /^(([a-z0-9_]+::)?[a-z0-9_]+\([^\)]*\))*$/i) {
        }
        else {
            return (0, "This line does not appear to contain a list of jobs that looks like (for example) 'J1() J2()'");
        }
        @jobs = $line =~ /((?:[a-z0-9_]+::)?[a-z0-9_]+\([^\)]*\))/ig;  # parens may be empty
    }
    else {
        # check for external dependencies
        if ($line =~ /[a-z0-9_]+::[a-z0-9_]+\([^\)]*\)/i) {
            return (0, "Only the first line of a section may have foreign dependencies");
        }
        if ($line =~ /^([a-z0-9_]+\([^\)]*\))*$/i) {
        }
        else {
            return (0, "This line does not appear to contain a list of jobs that looks like (for example) 'J1() J2()'");
        }
        @jobs = $line =~ /([a-z0-9_]+\([^\)]*\))/ig;  # parens may be empty
    }
        

    

    my @errors = ();
    my ($retval, $error);
        
    foreach my $job (@jobs) {
        ($retval, $error) = $self->_parseJob($job);
        if ($retval == 0) {
            push (@errors, $error);
        }
    }

    if (@errors) {
        return (0, join(", ", @errors));
    }

    # set the list of dependencies for the next iteration in
    # the loop
    #
    $self->{last_dependency} = $self->{current_dependency};

    return (1, "");
}



# ------------------------------------------------------------------------------
=pod

=over 4

=item _parseJob()

 Usage     : $self->_parseJob($job)
 Purpose   : Parse the job definition, create additional dependencies
             if necessary, and create the job.  If it's a recurring
             job, then create a bunch of 'repeat' jobs that are not
             dependent on the original job's predecessors, but on
             time dependencies only.
 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _parseJob {
    my ($self, $job) = @_;
    
    my ($family_name_with_colons, $family_name, $job_name, $args) = $job =~ /(([a-z0-9_]+)::)?([a-z0-9_]+)(\([^\)]*\))/i;
    my $local_job = 0;

    unless ($family_name) {
        $family_name = $self->{name};
        $local_job   = 1;
    }
    #$self->{families}->{$family_name} = 1;
    #$job_name = $family."::$job_name";

    my $job_object;
    if ($local_job) {
        if ($self->{jobs}->{$job_name}) { 
            $job_object = $self->{jobs}->{$job_name};   # job already exists in this family
        }
        else {
            # if jobname has ::, get family name
            # else family_name is this family's name
            # job_object = new (job_name, family_name)
            $job_object = TaskForest::Job->new(name => $job_name);  # create new job
            $self->{jobs}->{$job_name} = $job_object; 
        }

        # Set dependencies.  A dependency can be a time dependency or another job
        #
        $self->{dependencies}->{$job_name} = [] unless $self->{dependencies}->{$job_name};
        foreach my $dep (@{$self->{last_dependency}}) {
            push (@{$self->{dependencies}->{$job_name}}, $dep); 
        }
    }
    else {
        # external dependency
        $job_object = TaskForest::Job->new(name => $job_name, family => $family_name);  # create new job
        $self->{families}->{$family_name} = 1;
    }

    if ($local_job && $args =~ /^\(\S/) {  # We have additional dependencies if this is a local job
        my %args = eval ($args); 
        return (0, $@) if $@;
        
        # passed first level of checks
        # now make sure that the only things within the parentheses are valid keys
        my ($retval, $error) = $self->_verifyJobHash(\%args);
        if ($retval == 0) { return (0, $error); }
        
        #print "\$\@ is $@ and \$\! is $! and args is ", Dumper(\%args);
        $args{tz} = $self->{tz} unless $args{tz}; # time zone defaults to family time zone
        if ($args{start}) {                       # time dependency
            my $td = TaskForest::TimeDependency->new(start => $args{start}, tz => $args{tz});
            push (@{$self->{dependencies}->{$job_name}}, $td);
            push (@{$self->{time_dependencies}}, $td);
        }
        else {
            $args{start} = $self->{start};
        }

        ($job_object->{start} , $job_object->{tz}) = ($args{start}, $args{tz});
        
        if ($args{every} and $args{every} !~ /\D/) {
            $self->_createRecurringJobs($job_name, \%args, $job_object);
        }

        $job_object->{tokens} = [];
        if ($args{token}) {
            my @tokens = split(",", $args{token});
            foreach my $token (@tokens) {
                if ($token =~ /^([a-z0-9_])+$/i) { 
                    push (@{$job_object->{tokens}}, $token);
                }
                else {
                    return (0, "Bad token name: $token.  A token name can only contain the characters [a-zA-Z0-9.-_]");
                }
            }
        }

        if ($args{email}) {
            $job_object->{email} = $args{email};
        }
        else {
            $job_object->{email} = $self->{options}->{email};
        }

        if ($args{retry_email}) {
            $job_object->{retry_email} = $args{retry_email};
        }
        else {
            $job_object->{retry_email} = $self->{options}->{retry_email};
        }

        if ($args{num_retries}) {
            $job_object->{num_retries} = $args{num_retries};
        }
        else {
            $job_object->{num_retries} = $self->{options}->{num_retries};
        }

        if ($args{retry_sleep}) {
            $job_object->{retry_sleep} = $args{retry_sleep};
        }
        else {
            $job_object->{retry_sleep} = $self->{options}->{retry_sleep};
        }

        if ($args{no_retry_email}) {
            $job_object->{no_retry_email} = $args{no_retry_email};
        }
        else {
            $job_object->{no_retry_email} = $self->{options}->{no_retry_email};
        }

        if ($args{instructions_dir}) {
            $job_object->{instructions_dir} = $args{instructions_dir};
        }
        else {
            $job_object->{instructions_dir} = $self->{options}->{instructions_dir};
        }

        if ($args{retry_success_email}) {
            $job_object->{retry_success_email} = $args{retry_success_email};
        }
        else {
            $job_object->{retry_success_email} = $self->{options}->{retry_success_email};
        }
        
        if ($args{no_retry_success_email}) {
            $job_object->{no_retry_success_email} = $args{no_retry_success_email};
        }
        else {
            $job_object->{no_retry_success_email} = $self->{options}->{no_retry_success_email};
        }
        
    }
    
    # push this job into the dependency array for the jobs in the next line
    #
    push (@{$self->{current_dependency}}, $job_object);

    return (1, "");
        
}    


# ------------------------------------------------------------------------------
=pod

=over 4

=item _verifyJobHash()

 Usage     : $self->_verifyJobHash($args)
 Purpose   : Verify that the hash created has valid keys

 Returns   : 1 on success, 0 on failure
 Argument  : $args - a reference to a hash 
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _verifyJobHash {
    my ($self, $args) = @_;
    
    my $valid_job_args = {
        "start"                  => 1,
        "tz"                     => 1,
        "every"                  => 1,
        "until"                  => 1,
        "chained"                => 1,
        "token"                  => 1,
        
        "email"                  => 1,
        "retry_email"            => 1,
        "no_retry_email"         => 1,
        "num_retries"            => 1,
        "retry_sleep"            => 1,
        "instructions_dir"       => 1,
        "params"                 => 1,
        "retry_success_email"    => 1,
        "no_retry_success_email" => 1,

        
    };

    my @errors = ();

    foreach (keys %$args) {
        if (! ($valid_job_args->{$_})) {
            push(@errors, "'$_' is not a recognized attribute");
        }
    }

    if (@errors) {
        return (0, join(", ", @errors));
    }
    return (1, '');
}

# ------------------------------------------------------------------------------
=pod

=over 4

=item _createRecurringJobs()

 Usage     : $self->_createRecurringJobs($job_name, $args)
 Purpose   : If a job is a recurring job, create new jobs with a
             prefix of --Repeat_$n-- where $n specifies the
             cardinality of the repeat job.

             By default, the newly created jobs are *not* dependent on
             each other. They're only dependent on their start times.
             If the 'chained=>1' option is given in the family file,
             or in the options, then the jobs are dependent on each
             other.  This is, arguably, the more sensible behavior.

 Returns   : Nothing
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub _createRecurringJobs {
    my ($self, $job_name, $args, $job_object) = @_;

    my $chained = defined($args->{chained})? $args->{chained} : $self->{options}->{chained};
    # if it's chained then each job is dependent on the other.
    
    my $until = $args->{until};
    my ($until_mm, $until_hh);
    if ($until =~ /^(\d\d):(\d\d)$/) { $until_hh = $1; $until_mm = $2; }
    else {                             $until_hh = 23; $until_mm = 59; }

    # get an epoch value for the the until time
    #
    # Set the until_time to be based on the job or family timezone
    #my $until_dt = DateTime->now(time_zone => $args->{tz});
    my $until_dt = DateTime->from_epoch(epoch => &TaskForest::LocalTime::epoch());
    $until_dt->set_time_zone($args->{tz});
    $until_dt->set(hour       => $until_hh);
    $until_dt->set(minute     => $until_mm);
    $until_dt->set(second     => 0);
    $until_dt->set(nanosecond => 0);
    my $until_epoch = $until_dt->epoch();
   
    

    # get a start time epoch value, defaulting to the family start time
    #
    my ($start_dt, $start_hh, $start_mm);
    $args->{start} = $self->{start} unless $args->{start};       # default start is famil start
    ($start_hh, $start_mm) = $args->{start} =~ /(\d\d):(\d\d)/;
    #$start_dt = DateTime->now(time_zone => $args->{tz});
    $start_dt = DateTime->from_epoch(epoch => &TaskForest::LocalTime::epoch());
    $start_dt->set_time_zone($args->{tz});
    $start_dt->set(hour       => $start_hh);
    $start_dt->set(minute     => $start_mm);
    $start_dt->set(second     => 0);
    $start_dt->set(nanosecond => 0);
    

    # create a duration value that's added in every loop
    #
    my $every_duration = DateTime::Duration->new(minutes => $args->{every});
    my $next_dt = $start_dt + $every_duration;
    my $next_epoch = $next_dt->epoch();
    my $next_n = 0;
    my $last_job = $job_object;
    while ($next_epoch <= $until_epoch) {
        $next_n++;
        my $jn = "$job_name--Repeat_$next_n--";
        my $td = TaskForest::TimeDependency->new($next_dt);
        $self->{dependencies}->{$jn} = [$td];
        my $repeat_job_object = TaskForest::Job->new(name => $jn, tz=>$args->{tz}, start => $td->{start});
        $self->{jobs}->{$jn} = $repeat_job_object;
        if ($chained) {
            push(@{$self->{dependencies}->{$jn}}, $last_job)
        }

        $next_dt = $next_dt + $every_duration;
        $next_epoch = $next_dt->epoch();

        $last_job = $repeat_job_object;
    }
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item writeSemaphoreFile()

 Usage     : $self->_writeSemaphoreFile($file_name)
 Purpose   : Creates a semaphore file.  If the file already exists, do nothing. 
 Returns   : Nothing
 Argument  : Contents of the file
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub writeSemaphoreFile {
    my ($self, $file_name, $contents) = @_;

    if (-e $file_name) {
        return;
    }
    
    open (F, ">$file_name") || croak "Cannot touch file $file_name";

    print F $contents;
    
    close F;
}




# ------------------------------------------------------------------------------
=pod

=over 4

=item findDependentJobs()

 Usage     : $job_names = $self->findDependentJobs($job)
 Purpose   : Find all jobs that are dependent on $job, either directly or
             indirectly
 Returns   : An array ref of job names
 Argument  : The name of the job whose dependents you are looking for
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub findDependentJobs {
    my ($self, $job_name) = @_;

    my @result = ();

    # first make a reverse dependency list

    $self->{dependents} = {};
    foreach my $j (keys %{$self->{dependencies}}) {
        foreach my $dep (grep { ref($_) eq 'TaskForest::Job' }@{$self->{dependencies}->{$j}}) {
            push (@{$self->{dependents}->{$dep->{name}}}, $j);
        }
    }

    # now get the dependent jobs
    my $deps = $self->{dependents}->{$job_name};

    my $seen = {};

    while (my $j = shift(@$deps)) {
        push (@result, $j) unless $seen->{$j};
        $seen->{$j} = 1;
        unshift(@$deps, @{$self->{dependents}->{$j}}) if $self->{dependents}->{$j};
    }

    return \@result;
            
}



# ------------------------------------------------------------------------------
=pod

=over 4

=item convertTokenWaitToReady()

 Usage     : $got_necessary_tokens = $self->acquireAllTokens($job)
 Purpose   : Attempt to consume all tokens required by the specified job
             indirectly
 Returns   : 1 if the job is ready to run, 0 otherwise
 Argument  : The name of the job
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub convertTokenWaitToReady {
    my ($self) = @_;
    my $ok                = 1;
    my $log_dir           = &TaskForest::LogDir::getLogDir($self->{options}->{log_dir}, $self->{tz});
    my $lock_file         = "$log_dir/tokens.lock";

    # we need to acquire a lock before we can do anything
    #
    sysopen(FH, $lock_file, O_RDWR|O_CREAT);
    flock(FH, LOCK_EX);
        
    # first check to see if the token file has been created.  
    #
    my $token_file = "$log_dir/tokens.txt";

    # create token file if necessary
    if (! -e $token_file) {
        $self->createTokenFile($token_file);
    }

    # read token file
    #
    my $token_hash = $self->readTokenFile($token_file);

    # release any tokens if possible, essentially making $token_hash 'current'
    #
    $self->releaseTokens($token_hash);

    # attempt to acquire tokens
    #
    $self->acquireAllTokens($token_hash);

    # write token file
    #
    $self->createTokenFile($token_file, $token_hash);
    

    # release the lock
    #
    flock(FH, LOCK_UN);
    close FH;
    
    return $ok;
}

sub acquireTokens {
    my ($self, $token_hash, $job_name) = @_;

    my $job = $self->{jobs}->{$job_name};

    my @temp_list;
    my $ok = 1;
    
    foreach my $token_name (@{$job->{tokens}}) {
        my $max_token_count = $token_hash->{$token_name}->{number};
        my $cur_token_count = 0;
        if ($token_hash->{$token_name}->{consumers}) { 
            $cur_token_count = scalar(@{$token_hash->{$token_name}->{consumers}});
        }
        if ($cur_token_count < $max_token_count) {
            push(@temp_list, $token_name);
        }
        else {
            $ok = 0;
        }
    }
    if ($ok) {
        # mark tokens as acquired - all or nothing
        foreach my $token_name (@temp_list) {
            push (@{$token_hash->{$token_name}->{consumers}}, $job->{unique_id});
        }
        return 1;
        #$job->{status} = 'Ready';
    }
    return 0;
                
    # for each token in the jobs list of tokens
    #   figure out how many tokens can be there (max), from options
    #   if length of consumers < that, acquire token - add it to a temp list
    #
    # if temp list is full list of job tokens, then add temp list to consumers and return 1
    # else return 0
}



sub acquireAllTokens {
    my ($self, $token_hash) = @_;

    foreach my $job_name (sort (keys %{$self->{token_jobs}})) {
        my $job = $self->{token_jobs}->{$job_name};
        if ($self->acquireTokens($token_hash, $job_name)) { 
            # move to ready state and ready 'queue'
            $job->{status} = 'Ready';
            $self->{ready_jobs}->{$job_name} = $job;
        }
    }
    
}


# What happens in the following case:
# 01 Job J using token T runs
# 02 Job J Completes
# 03 Job J is rerun
# 04 TskForest Cycles
#
# You can't rely on the existence of the file (alone)
# You have to look at the pid
# You could do a status!

sub releaseTokens {
    my ($self, $token_hash) = @_;

    my $completed_jobs_by_unique_id = {};
    foreach my $job_name (keys(%{$self->{jobs}})) {
        if ($self->{jobs}->{$job_name}->{status} eq 'Success' ||
            $self->{jobs}->{$job_name}->{status} eq 'Failure') {
            $completed_jobs_by_unique_id->{$self->{jobs}->{$job_name}->{unique_id}} = $self->{jobs}->{$job_name}; 
        }
    }

    foreach my $token_name (keys(%$token_hash)) {
        my $new_consumers = [];

        # consumers is a list of unique_ids
        # remove from the consumers list anything that we know has completed
        #
        my @new_consumers = grep { !($completed_jobs_by_unique_id->{$_}) }
                                 @{$token_hash->{$token_name}->{consumers}};
        $token_hash->{$token_name}->{consumers} = \@new_consumers;

        # now we know who the consumers are, we know how many users there are.
        # this step removes names from the token_hash->{$token_name}->{consumers};
    }
}

sub readTokenFile { 
    my ($self, $token_file) = @_;

    if (open(F, $token_file)) {
        my $data = join("", <F>);
        close F;
        $data =~ /(.*)/s;
        $data = $1;
        my $hash = eval($data);
        return $hash;
    }
    else {
        confess("Cannot read token file $token_file");
    }
}

sub createTokenFile {
    my ($self,
        $token_file,
        $token_hash) = @_;
    
    $token_hash      = $self->{options}->{token} unless $token_hash;
    
    if (open (F, ">$token_file")) {
        print F "my ", Dumper($token_hash);
        close F;
    }
    else {
        confess("Can't write to token_file $token_file");
    }
}


sub defOr {
    my ($value, $or) = @_;
    return $value if defined($value);
    return $or;
}



1;



    
    
