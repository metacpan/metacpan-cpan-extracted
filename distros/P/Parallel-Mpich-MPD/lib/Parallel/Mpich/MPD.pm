package Parallel::Mpich::MPD;

use warnings;
use strict;
use File::Temp;
use IO::All;
use Carp;
use Time::HiRes qw( usleep);
use Data::Dumper;
use Parallel::Mpich::MPD::Common;
use Parallel::Mpich::MPD::Job;

=head1 NAME

Parallel::Mpich::MPD - Mpich MPD wrapper

=item I<$VERSION>


=cut

our $VERSION = '0.9.3';

=head1 SYNOPSIS
    use Parallel::Mpich::MPD;
    
    # VERBOSE LEVEL
    #$Parallel::Mpich::MPD::Common::WARN=1;
    #$Parallel::Mpich::MPD::Common::DEBUG=1;
    
    #CHECK ENV
    Parallel::Mpich::MPD::Common::env_Hostsfile(/path/to/machinesfile);
    Parallel::Mpich::MPD::Common::env_MpichHome(/path/to/mpdhome);
    Parallel::Mpich::MPD::Common::env_Check();
    
    #CHECK MPD AND NETWORK
    my %hostsup;
    my %hostsdown;
    my %info=Parallel::Mpich::MPD::info();    #check mpd master
    print Dumper(\%info)
    %hostsup= Parallel::Mpich::MPD::Common::checkHosts(hostsdown => \%hostsdown );    #check ping and ssh on machines 
    %hostsup= Parallel::Mpich::MPD::check( reboot =>1:0, hostsdown=>\%hostsdown);     #check mpds instances and try to repair
    ...    
    
    # USE MPD
    Parallel::Mpich::MPD::boot();     #start mpd instances defined by default machinesfile
    my $alias1=Parallel::Mpich::MPD::makealias();
    if Parallel::Mpich::MPD::createJob(cmd => $cmd, params => $parms, $machinesfile => $hostsfile, alias => $alias1)){
      my $job=Parallel::Mpich::MPD::findJob(jobalias => $alias, getone => 1);
      $job->sig_kill() if defined $job;
    }

=head1 DESCRIPTION

This I<Parallel::Mpich::MPD>, a wrapper module for MPICH2 Process Management toolkit from L<http://www-unix.mcs.anl.gov/mpi/mpich2/>. 
The wrapper include the following tools: basic configuration, mpdcheck, mpdboot, mpdcleanup, mpdtrace, 
mpdringtest, mpdallexit, mpiexec, mpdsigjob and mpdlistjobs.

=over 4

=item boot(hosts => @hosts, machinesfile => $machines, checkOnly => 1|0, output => \$output)
  
starts a set of mpd's on a list of machines. boot try to verify that the hosts in the host 
file are up before attempting start mpds on any of them. 
  
=item rebootHost(host => $hostname)

restart mpd on the specified host. rebootHost will kill old mpds before restarting a new one. 
The killed MPDS are filtered by specific port and host.

=item check(machinesfile => $file, hostsup => \%hosts, hostsdown => \%hostsdown , reboot => 1)

Check if MPD master and nodes are well up. If MPD master is down it try to ping and ssh machines.   
If you use the option reboot, check will try to restart  mpd on specified machines or to reboot the master. 
  
=item info( )

return an %info of the master with the following keys (master, hostname, port)
  
=item validateMachinesfile(machinefiles => $filename)

check with mpdtrace if all machines specified by filename are up. If not, a temporary file is 
created with the resized machinesfile 

=item shutdown( )

causes all mpds in the ring to exit

=item createJob({cmd => $cmd , machinesfile=> $filename, [params => $params], [ncpu => $ncpu], [alias => $alias])
 
start a new job with the command line and his params. It return true if ok.
  WARNING ncpu could be redefined if mpdtrace return à small hosts list
     
Example:
  
  Parallel::Mpich::MPD::createJob(cmd => $cmd, params => $parms, ncpu => '3', alias => 'job1');

=item listJobs([mpdlistjobs_contents=>$str])

Return an Parallel::Mpich::MPD::Job array for all available jobs
If mpdlistjobs_contents argument is present, the code will not call mpdlistjobs but 
take the parameter as a fake results of this command

=item findJob([%criteria][, return=>(getone|host2pidlist))

find a job from crtiteria. It return a Job instance or undef for no match

=over 4

=item Criteria can be of

=item username=>'somename' or username=>\@arrayOfNames

=item jobid=>'somename' or jobid=>\@arrayOfJobid

=item jobalias=>'somename' or jobalias=>\@arrayOfJobalias

To set an array of names;

  $criteria{psid} [&& $criteria{rank}]  You can select psid from the specified rank.
  $criteria{reloadlist}  force the call of listjobs

=back

=head4 return value

By default (no return=>... argument), returned value will be a hash (or a hash ref, depending on context), {jobid1=>$job1, jobid2=>job2,...}

=over 4

=item return=>'getone'

Will force to return the one job matching, or undef if none or error if many.

=item return=>'host2pidlist'

return a hash (or a ref to this hash, depending on context), host=>\@pidlist

=back

=head4 Examples

=begin verbatim

Parallel::Mpich::MPD::findJob(alias => 'olivier1', return=>'getone')->sendSig();
my %kobs=Parallel::Mpich::MPD::findJob(alias => ['olivier1', 'olivier2']);
my $refjobs=Parallel::Mpich::MPD::findJob(alias => ['olivier1', 'olivier2']);
my $job=Parallel::Mpich::MPD::findJob(jobid => '1@linux02_32996', return=>'getone');

=end verbatim

=item trace([hosts => %hosts], long => 1)

  Lists the  hostname of each of the mpds in the ring
  return true if ok
  
  [long=1] shows full hostnames and listening ports and ifhn

=item makealias( )

  "handle-" + PID + RAND(100) + Instance COUNTER++
  
  return a uniq string  alias
  
=item clean([hosts => %hosts]  [killcmd=>"cmd"])

Removes the Unix socket on local (the default) and remote machines
This is useful in case the mpd crashed badly and did not remove it, which it normally does
  [hosts => %hosts]   use specified hosts ,   
  [$cleancmd="cmd"]   user defined kill command


=head1 AUTHOR

Olivier Evalet, Alexandre Masselot, C<< <alexandre.masselot at genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-parallel-mpich-mpd at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parallel-Mpich-MPD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parallel::Mpich::MPD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parallel-Mpich-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parallel-Mpich-MPD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parallel-Mpich-MPD>

=item * Search CPAN

L<http://search.cpan.org/dist/Parallel-Mpich-MPD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Olivier Evalet, Alexandre Masselot, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

require Exporter;
our $cached_all_jobs={};
our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);


@EXPORT = qw();
@EXPORT_OK = ();


#sub new{
#  my $pkg=shift;
#  my $this={};
#  env_Init() unless defined(%env);
#  bless $this, $pkg;
#  return $this;
#}

# hosts => @hosts, machinesfile => $machines, checkOnly => 1|0,check => \$output
sub boot{
  my %params=@_;
  env_Init();
  my $cmdparms="";  #only one instance of mpd should run
  my $usermachinesfile;
  $usermachinesfile.="$params{machinesfile}" if defined $params{machinesfile};
  $usermachinesfile.=Parallel::Mpich::MPD::Common::__param_buildHost(@{$params{hosts}}) if defined $params{hosts};
  
#   if (defined $env{info}{user}){
#     $cmdparms.=" -u $env{info}{user}";
#   }

  if (defined $env{conf}{rpc}){
    $cmdparms.=" -r $env{conf}{rpc}";
  }
  if (defined $usermachinesfile){
    $cmdparms.=" -f $usermachinesfile"; 
    $cmdparms.=" -n ".Parallel::Mpich::MPD::Common::nbHostInMachinefile($usermachinesfile);
  }elsif (defined $env{conf}{mpd}{hostsfile}){
    my ($ncpu,$stripfile)=Parallel::Mpich::MPD::Common::stripMachinefile($env{conf}{mpd}{hostsfile});
    $cmdparms.=" -f $stripfile "; 
    $cmdparms.=" -n $ncpu ";
  }
#   if (defined $env{conf}{mpiexec}{ncpu}){
#     $cmdparms.=" -n ".($env{conf}{mpiexec}{ncpu}+1); 
#   }
  if (defined($params{checkOnly})){
    $cmdparms.=" --chkuponly --verbose "; 
  }elsif (defined($params{verbose})){
    $cmdparms.=" --verbose "; 
  }

  my %execparms=(cmd => commandPath('mpdboot')." $cmdparms");
  if (defined($params{output})){
    $execparms{stdout}=$params{output}
  }
  my $ret=Parallel::Mpich::MPD::Common::__exec(%execparms);
  
  
  return $ret==0;
}

sub info{
#genebio-95_59850 (192.168.173.95)
  my %params=@_;
  env_Init();
  my $stdout="";
  my $stderr="";
  my $jobret=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdtrace')." -l",stdout => \$stdout, stderr=>\$stderr);
  my @hosts=split /\n/, $stdout;
  my %info=();
  if ($jobret==0){
    $info{master}=$hosts[0];
    my $tmp=$info{master};
    $tmp=~ s/(\S+)_(\d+)/$info{hostname}=$1;$info{port}=$2/e;
    print "DEBUG:MPD::info:". Dumper(\%info) if $Parallel::Mpich::MPD::Common::DEBUG==1;
  }
  return %info;
}


sub rebootHost{
  my %params=@_;
  my $stdout;
  env_Init();
  
  my %mpdinfo=();
  unless (defined($params{host})){
    print STDERR "ERROR:rebootHost(1): you should define an hostname where to start mpd \n";
    return %mpdinfo;
  }
  
  %mpdinfo=info();
  
  if((my $c=%mpdinfo) eq "0"){
    print STDERR "ERROR:rebootHost(2): MPD seems dead, restart the mpd system \n";
    return undef;
  }
  
  #TODO make this better ;)
  # pkill -f mpd.py
  my $kill;
  my $cmd;
  if (system("pkill --help &>/dev/null")){
    $kill="pkill -U $env{info}{user} -f mpd.py";
    $cmd="ssh $params{'host'} 'pkill -U $env{info}{user} -f mpd.py'";
  }else{
    $kill="ps -U $env{info}{user} -o pid,command|grep -e \"$mpdinfo{hostname} -p $mpdinfo{port}\" |grep -v grep |cut -d \" \" -f2";
    $cmd="ssh $params{'host'} '$kill|xargs kill 2>/dev/null'";
  }
  my $ret=system $cmd;
  
  $cmd="ssh $params{'host'} ". commandPath('mpd')." -h $mpdinfo{hostname} -p $mpdinfo{port} --ncpus=1 -e -d";
  
  my $res=Parallel::Mpich::MPD::Common::__exec(cmd => $cmd, stdout => \$stdout);
  
  if ($res!=0){
    print STDERR "ERROR:rebootHost(3): Could not start mpd on host $params{host} \n";
    return undef;
  }
  
  print "INFO:restart mpd on $params{'host'}:$mpdinfo{port} \n" if $Parallel::Mpich::MPD::Common::WARN==1;
    
  #check mpdtrace to detect the new host
#   my %hosts;
#   my $res=trace(hosts => \%hosts);
#   return (defined($hosts{$params{host}}) && $hosts{$params{host}}==1)?1:undef;
  return 1;
}

# TODO check should also check on each nodes that:
#  $HOME/.mpd.conf owner and attr=600 
#  check DNS hostname for master and nodes

# use case check
# =================

# 1) unplug network wire
# 2) some mpd died correctly 
# 3) some mpd died badly
# 4) all nodes are dead  
  
#
#  
#  machinesfile => $file, hostsup => \%hosts, hostsdown => \%hostsdown , reboot => 1 
sub check{
  my %params=@_;
  env_Init();
  my $out="";
  my %hosts=();
  my $should_resize;
  
  my ($ncpu,$stripfile)=Parallel::Mpich::MPD::Common::stripMachinefile($env{conf}{mpd}{hostsfile}) unless defined $params{machinesfile};
  
  my $machinesfile=(defined $params{machinesfile})?$params{machinesfile}:$stripfile;
  #trace hosts
  
  #1) check mpdtrace hosts
  my $res=trace(hosts => \%hosts);
  
  my $machines=io($machinesfile)->slurp;
  my %hostsdown;
  if ($res){
    #compare hosts result with the input machinesfile 
    my %hostsup;
    
    foreach (split /[\n\r]/, $machines){
      next unless /\S/;
      next if /#.*$/;
      s/([^.]+).*$/$1/;
      if (defined($hosts{$_}) && $hosts{$_}==1){
	$hostsup{$_}=1;
      }else{
        $should_resize=1;
	if (defined $params{reboot} && $params{reboot}==1){
	  $hostsdown{$_}=1 unless(defined(rebootHost(host =>"$_")));
	}else{
	  $hostsdown{$_}=1;
	}
      }
    }
    # here the status is wrong, cluster should be resized
    if (defined $should_resize && defined $params{reboot} && $params{reboot}==1){
      %hostsup=check(machinesfile => $machinesfile);
    }
    %{$params{hostsup}}=%hostsup if defined $params{hostsup};
    %{$params{hostsdown}}=%hostsdown if defined $params{hostsdown};
    
    return %hostsup ;
    

  }else{
    foreach (split /[\n\r]/, $machines){
      next unless /\S/;
      next if /#.*$/;
      s/([^.]+).*$/$1/;
      $hostsdown{$_}=1;
    }
    %{$params{hostsdown}}=%hostsdown if defined $params{hostsdown};
    
    print "ERROR:MPD::check():  MPD seems down, it's a really bad news!\n" if ($Parallel::Mpich::MPD::Common::WARN == 1);
    if (defined $params{reboot} && $params{reboot}==1){
      print "INFO: Clean all MPD.\n";
      clean(pkill=>1);
      print "INFO: trying to restart MPD.\n";
      boot();
      return check(machinesfile => $machinesfile, hostsup=>$params{hostsup}, hostsdown=>$params{hostsdown});
    }
  }
  
  #2) check vailable hosts (ping + ssh publicKey) if mpdtrace return FALSE
  checkHosts(machinesfile => $machinesfile, hostsup => \%hosts);
  unless (keys %hosts){
    #
    # FATAL ERROR: the cluster is dead
    #
    die "ERROR: your cluster is dead! All Hosts defined in $machinesfile are down.";
  }

  
  #3) should clean and restart mpd ?


  return %hosts=();
}






#use a cached jobs to force the update on each getJobs call!!!
sub __jobsFactory{

  my $myjobs=shift;
  my $host={};
  my @allentries;
  my $job;#={infos => {jobid=>''}};

  $cached_all_jobs={};

  #map result to hash
  foreach (split/\n\n/, $myjobs){
    my %h;
    s/(\S+)[\s=]+(\S*)?$/$h{$1}=$2/emg;
    push @allentries, \%h;
  }

  #order job
  foreach (@allentries){
    my $data=$_;
    $job=$cached_all_jobs->{$data->{jobid}}||=Parallel::Mpich::MPD::Job->new(jobid=>$data->{jobid});
#    if (!$job || ($data->{jobid} ne $job->jobid)){
#      $job=P;
#      =$job;
#      $job->jobid($data->{jobid});
      $job->jobalias($data->{jobalias});
      $job->username($data->{username});
#    }
    $host={};
    $host->{host} =$data->{host};
    $host->{pid}  =$data->{pid};
    $host->{sid}  =$data->{sid};
    $host->{rank} =$data->{rank};
    $host->{pgm}  =$data->{pgm};
    $job->hosts_push($host);
  }

  print STDERR (values %{$cached_all_jobs}) if ($Parallel::Mpich::MPD::Common::DEBUG == 1);
  return values %{$cached_all_jobs};
}



sub validateMachinesfile{
  my %params=@_;
  my $trace="";
  my %hosts=();
  return undef unless defined $params{machinesfile};
  my $retfile=$params{machinesfile};
  
  
  if ( defined($params{machinesfile}) && -e $params{machinesfile}){
    #1) check mpdtrace hosts
    my $res=trace(hosts => \%hosts);
    
    if ($res){
      #compare hosts result with the input machinesfile 
      my $machines=io($params{machinesfile})->slurp;
      print "DEBUG:validateMachinesfile(1) : machines=$machines\n\n" if ($Parallel::Mpich::MPD::Common::DEBUG == 1);
      
      my $fhosts = new File::Temp(UNLINK=>0, TEMPLATE => File::Spec->tmpdir."/$TMP_MPD_PREFIX-machines-XXXX");
      foreach (split /[\n\r]/, $machines){
	next unless /\S/;
	next if /#.*$/;
        s/([^.]+).*$/$1/;
	
	if (defined($hosts{$_}) && $hosts{$_}==1 ){
          print  $fhosts $_."\n";
          print  "validated machines : ".$_."\n" if ($Parallel::Mpich::MPD::Common::DEBUG == 1);
	}else{
	  $retfile=$fhosts->filename;
          print STDERR "WARNING: node $_ defined on machinesfile [".$params{machinesfile}."] is not available\n";
	}
      }
    }else{
      print STDERR "ERROR:validateMachinesfile(1): fatal mpd error \n";
    }
  }else{
      print STDERR "ERROR:validateMachinesfile(2): could not open file : ".$params{machinesfile}."\n";
  }

  return $retfile;
}


sub isJobRegistered{
  my ($alias)=@_;
  # we don't know if job is register without alias
  return 1 unless defined $alias;
  if(system(commandPath('mpdlistjobs')." 2>/dev/null|grep -qe \"alias.*$alias\"")){
    return 0;
  }else{
   print STDERR "INFO: job $alias is registered \n" if ($Parallel::Mpich::MPD::Common::WARN == 1);
   return 1;
  }
}

sub waitJobRegistration{
  my ($alias)=@_;
  my $TIMEOUT=0;
  do{
    usleep (400*1000);
    $TIMEOUT+=400;
  }while(!isJobRegistered($alias) && $TIMEOUT<10000);
  return 1;
}



# TODO check that the machine file contains booted hosts
# FIXME create job should wait until job is correctly registered by mpd.
sub createJob{
  my %params=@_;
  env_Init();
  my $spawn = 'yes';
  $spawn=$params{spawn} if exists $params{spawn};
  my $_out;
  my $_err;
  my $_pid="";

  my $mpiexecArgs="";
  $mpiexecArgs.=" -a $params{alias}" if defined($params{alias});

  my $inputfile=(defined $params{machinesfile})?$params{machinesfile}:Parallel::Mpich::MPD::Common::env_Hostsfile();
  my $machinesfile=validateMachinesfile(machinesfile => $inputfile);
  $mpiexecArgs.=" -machinefile ".$machinesfile;

  $mpiexecArgs.="-u $params{user}"  if defined($params{user});

  #TODO much more here see mpiexec -hosts
  #$mpiexecArgs.=" -n $params{ncpu}" if defined($params{ncpu});
  
  if(defined $params{ncpu} && "$inputfile" eq "$machinesfile"){
    $mpiexecArgs.=" -n $params{ncpu}";
  }else{
    my $n=Parallel::Mpich::MPD::Common::nbHostInMachinefile($machinesfile);
    $mpiexecArgs.=" -n $n";
  }
  $mpiexecArgs.=" -env LD_ASSUME_KERNEL ".$ENV{LD_ASSUME_KERNEL} if ($ENV{LD_ASSUME_KERNEL});

  if (! defined($params{cmd})){
    carp "ERROR: key cmd not available";
    return undef; 
  }
  # hosts info 
  my $cmdparms="";#.="-f ".Parallel::Mpich::MPD::Common::__param_buildHost(@hosts) if defined(@hosts);
  my $cmd=commandPath('mpiexec')." $mpiexecArgs $params{cmd} $params{params}";
  print STDERR "hostfile=".$machinesfile."\n";


  my %args=(cmd => $cmd);
  $args{params}=\$params{params} if (defined($params{params}) );
  $args{spawn}=\$params{spawn} if (defined($params{spawn}) );
  $args{stdout}=$params{stdout} if (defined($params{stdout}) );
  $args{stderr}=$params{stderr} if (defined($params{stderr}) );
  $args{pid}=$params{pid} if (defined($params{pid}) );
  
  my $ret=Parallel::Mpich::MPD::Common::__exec(%args);
  waitJobRegistration($params{alias}) if defined($params{spawn}) && defined($params{alias});
  
  
  return $ret==0;
}

sub listJobs{
  my %hparams=@_;
  env_Init();
  my $stdout="";
  my $stderr;
  if(defined ($hparams{mpdlistjobs_contents})){
    $stdout=$hparams{mpdlistjobs_contents};
  }else{
    my $res=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdlistjobs'), stdout => \$stdout);
#    my $cmd=commandPath('mpdlistjobs');
#    $stdout=`$cmd`;
    print "DEBUG: mpdlistjobs stdout= $stdout \n" if ($Parallel::Mpich::MPD::Common::DEBUG == 1);
    if ($res!=0){
      carp "error executing line mpdlistjobs command\n";
      return undef; 
    }
    if ($stdout eq ""){
      return undef;
    }
  }
  

  return __jobsFactory($stdout);
}




#find a job from crtiteria. It return an Hash of Jobs instance or null for no match
#params
#  $criteria{pid} [ && $criteria{rank}]
#  $criteria{jobalias}
#  $criteria{username}
#  $criteria{reloadlist}
#  $criteria{getone} return the first occurrence 

sub findJob{
  my %criteria=@_;
  #Transform criteria from array or scalar into a hash 
  foreach my $k(qw(jobalias username jobid)) {
    next unless defined $criteria{$k};
    if(ref($criteria{$k}) eq 'ARRAY'){
#      print STDERR "k=[$k]\n";
      my %h;
      foreach(@{$criteria{$k}}){
#	print STDERR "\$_=[$_]\n";
	$h{$_}=1;
      }
      $criteria{$k}=\%h;
    }else{
      #scalar, make it array
      $criteria{$k}={$criteria{$k}=>1};
    }
  }

  #force to reload the list
  listJobs() if defined($criteria{reloadlist});

#  # je ne comprend pas pourquoi $jobs->{$job->jobid} est un tableau!!!
#  undef my $jobs;
#  foreach my $job (values %{$cached_all_jobs}){
#    if ($job->equals(%criteria)){
#      #WRONG: returns the first one!
#      return $job if (defined($criteria{getone}));

#      if (defined($criteria{jobalias})) {
#        push @{$jobs->{$job->jobid}}, $job;

#      }elsif (defined($criteria{username})) {
#        push @{$jobs->{$job->jobid}}, $job;
#      }elsif (defined($criteria{jobid})) {
#        push @{$jobs->{$job->jobid}},$job;
#      }elsif (defined($criteria{pid})) {
#        push @{$jobs->{$job->jobid}}, $job;
#      }
#    }
#  }
  my %retjobs;
  foreach my $j (values %{$cached_all_jobs}){
    if((defined($j->jobid) && $criteria{jobid}{$j->jobid}) ||
       (defined($j->jobalias) && $criteria{jobalias}{$j->jobalias}) ||
       (defined($j->username) && $criteria{username}{$j->username})){
      $retjobs{$j->jobid}=$j;
    }
  }

  if ($criteria{return} && $criteria{return} eq 'getone'){
    #no match!!
    return undef unless %retjobs;

    my $sz=keys %retjobs;
    print __PACKAGE__."::findjobs() ".Dumper \%retjobs if $Parallel::Mpich::MPD::Common::WARN;
    
    if($sz==1){
      #OK
      return (values %retjobs)[0];
    }else{
      #too many matches
      die "too many matches ($sz) for criteria
    jobid=>   (".($criteria{jobid} || join('|', keys %{$criteria{jobid}})).")
    jobalias=>  (".($criteria{jobalias} || join('|', keys %{$criteria{jobalias}})).")
    username=>(".($criteria{username} || join('|', keys %{$criteria{username}})).")
";
    }
  }elsif ($criteria{return} && $criteria{return} eq 'host2pidlist'){
    my %rethash;
    foreach (values %retjobs){
      my @h=$_->hosts();
      foreach (@h){
	$rethash{$_->{host}}{$_->{pid}}=$_->{pgm};
      }
    }
    return wantarray?%rethash:\%rethash;
  }else{
    return wantarray?%retjobs:\%retjobs;
  }
}


sub trace{
  my %params=@_;
  env_Init();
  my $stdout="";
  my $jobret=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdtrace'),stdout => \$stdout);
  if (defined($params{hosts}) && $jobret==0){
    my %tmp=%{$params{hosts}};
    foreach (split /\n/, $stdout){
      $tmp{$_}=1;
    }
    %{$params{hosts}}=%tmp;
  }
  return $jobret==0;
}


#
# clean 
# Removes the Unix socket on local (the default) and remote machines
# This is useful in case the mpd crashed badly and did not remove it, which it normally does
# params
# [hosts => %hosts]  pkill=>1
sub clean{
  my %params=@_;
  env_Init();
  my $cmdparms;
  if (defined $params{hosts}){
    $cmdparms.=" -f ".Paralle l::Mpich::MPD::Common::__param_buildHost(@{$params{hosts}}) ;
  }else{
    $cmdparms.=" -f ".Parallel::Mpich::MPD::Common::stripMachinefile($env{conf}{mpd}{hostsfile});
  }
  $cmdparms.=" -k \"pkill -U $env{info}{user} -f mpd.py\"" if defined $params{pkill};

  my $cmd=commandPath('mpdcleanup')."$cmdparms 2>/dev/null";
#  print STDERR $cmd."\n";
  return system ($cmd);
}

sub shutdown{
  my $stdout="";
  my $stderr="";
  env_Init();
  my $ret2=Parallel::Mpich::MPD::Common::__exec(cmd => commandPath('mpdallexit'));
  $ret2=clean() if $ret2;
  return $ret2==0;
}

our $aliasCounter=0;
sub makealias{
  
  # alias is hablde + PID + RAND(100) + COUNTER++
  # inside a thread the aliascounter is a copy ! 
  return "handle-$$-".int(rand(100))."-".($aliasCounter++);
}


1; # End of Parallel::Mpich::MPD
