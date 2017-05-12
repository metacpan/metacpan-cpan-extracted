#!/usr/bin/env  perl

# read pidlist avery N seconds and (kill -9|STOP) a random pid
# usage mpd-kill.pl --time=5 --hostname=node-0.phenyxtest --username=evaleto --loop

use Data::Dumper;
use Parallel::Mpich::MPD;
use File::Temp;
use IO::All;

use Getopt::Long;
my($verbose, $machinesfile, $repair, $mpdhome, $help, $debug, $mailto);

if (!GetOptions(
		"verbose" =>\$verbose,
 		"machinesfile=s" =>\$machinesfile,
 		"repair" =>\$repair,
 		"mailto=s" =>\$mailto,
 		"mpdhome=s" =>\$mpdhome,
 		"help" =>\$help,
 		"debug" =>\$debug,
)|defined($help)){
  printf STDERR "Usage:\n";
  printf STDERR "$0 --verbose --repair --machinesfile=/path/to/machinesfile --mpdhome=/path/to/mpdhome\n\n";
  exit 0;
}

my $mailfile=new File::Temp(UNLINK=>0, TEMPLATE => File::Spec->tmpdir."/mpd-check-XXXX");

if (defined $mailto){
  use Mail::Sendmail;
  open(STDOUT, "> ".$mailfile->filename)  or die "Can't redirect stdout: $!";
  open(STDERR, ">&STDOUT")            or die "Can't dup stdout: $!";
}



$Parallel::Mpich::MPD::Common::WARN=1;
$Parallel::Mpich::MPD::Common::DEBUG=1  if defined $debug;

#
# Check current user
#
my $id=`id -u`;
chop $id;
if ($id == 0){
  print STDERR "ERROR: You could not run script as user root, exit now!\n";
  exit 1;
}


#
# Check configuration
#
print "Checking MPD environnement ...\n";
Parallel::Mpich::MPD::Common::env_Hostsfile($machinesfile) if defined $machinesfile;
Parallel::Mpich::MPD::Common::env_MpichHome($mpdhome) if defined $mpdhome;
Parallel::Mpich::MPD::Common::env_Check();
Parallel::Mpich::MPD::Common::env_Print()if defined $debug;

#
#Print machinesfile
#

print "machinesfile: ".Parallel::Mpich::MPD::Common::env_Hostsfile()."\n\n";
#
#Check mpd info
#
print "1) Checking MPD master informations ...\n";
my %info=Parallel::Mpich::MPD::info();
my $mpd_is_down;
my $machine_is_down;
my $mpdnode_is_down;
my $sendemail;
if ((my $c=%info)  eq "0"){
  print STDERR "ERROR:MPD seems down, could not read master informations\n";
  $mpd_is_down=1;
  $sendemail=1;
}
my %hostsdown; 
print "2) Checking machines for ping and ssh...\n";
Parallel::Mpich::MPD::Common::checkHosts(hostsdown => \%hostsdown );

if (($c = %hostsdown) ne "0" ){
  print STDERR "ERROR: machine(s) doesn't respond, please check why?\n";
  $machine_is_down=1;
  $sendemail=1;
}
$repair=(defined($repair))?" (and try to repair) ":"";
print "3) Checking $repair MDP nodes state ...\n\n";
my %hostsdown;
my %hostsup=Parallel::Mpich::MPD::check(reboot =>(defined $repair)?1:0, hostsdown=>\%hostsdown);

if (($c = %hostsdown) eq "0" ){
  undef $machine_is_down;
  undef $mpd_is_down;
}

print "\n";
print "REPORT:\n";
printf "%-60s %s\n", " - all machines are up   (ping/ssh)" , (defined($machine_is_down))?"[no]":"[yes]";

printf "%-60s %s\n", " - MDP master is up and working" , (defined($mpd_is_down))?"[no]":"[yes]";

printf "%-60s %s\n", " - MPD nodes are up", (($c=%hostsdown) ne "0" || defined($mpd_is_down))?"[no]":"[yes]" ;


unless (($c=%hostsdown) eq "0" ){
  foreach (keys %hostsdown){print "\t$_ is not available\n";};
}

if (defined ($mailto) && defined($sendemail)){
  my $mail=IO::All::io($mailfile->filename)->slurp;
  %send=(To => $mailto, From => $mailto, Subject => "MPD check report", Message => $mail);
  sendmail(%send) or die $Mail::Sendmail::error;
}

print "\n";



