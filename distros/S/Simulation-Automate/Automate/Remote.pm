package Simulation::Automate::Remote;

use vars qw( $VERSION );
$VERSION = "1.0.1";

#################################################################################
#                                                                              	#
#  Copyright (C) 2003 Wim Vanderbauwhede. All rights reserved.                  #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

#headers
#
#Support module for remote runs
#This implementation requires:
#-ssh access to remote host
#-scp access to remote host
#-rsync server on the local host
#-or,alternatively, an NFS mounted home directory
#-as such, it'll probably only work on Linux and similar systems
#
#$Id$
#

#usage:
#sub synsim {
#if(&check_for_remote_host==1){
#&run_on_remote_host()
#} else {
#&run_local(); # new name for sub synsim
#}
#}

use strict;
use Cwd;
use Exporter;

@Simulation::Automate::Remote::ISA = qw(Exporter);
@Simulation::Automate::Remote::EXPORT = qw(
		     &check_for_remote_host
		     &run_on_remote_host
                  );
#------------------------------------------------------------------------------
sub check_for_remote_host {
(!@ARGV || $ARGV[@ARGV-1]=~/^\-/) && return 0; # not a host name
my $arg=@ARGV[@ARGV-1];

my $remotehost='';
if(($arg!~/\.data/)&&($arg ne '-h')) {
$remotehost=pop @ARGV;
chomp(my $reply=`ssh $remotehost hostname -s 2>&1`);
my $remotehostshort=$remotehost;
$remotehostshort=~s/\..*$//;
if($reply ne $remotehostshort){
$remotehost.='FAIL';
}
}
return $remotehost; #0: local; 1: remote OK; 2: remote FAIL
} #END of check_for_remote_host
#------------------------------------------------------------------------------
sub run_on_remote_host {
my $remotehost=shift;
if( $remotehost=~s/FAIL//) {
die "Could not establish SSH connection to $remotehost\n";
}
my $datafile=@ARGV[@ARGV-1];
my $user=$ENV{USER};
chomp(my $localhost= `hostname -s 2>&1`);

my $localsynsimpath=cwd();
my $rundir=$localsynsimpath;
my $homepath=$localsynsimpath;
$homepath=~s/$user.*$//;
$homepath.=$user;
$rundir=~s/^.*\///;
$localsynsimpath=~s/\w+$//; #dangerous!
$localsynsimpath=~s/.*$user\///; #dangerous!
$localsynsimpath=~s/\/$//;

my $remotesynsimpath=$localsynsimpath;

chomp(my $simdir=`egrep '^SIMTYPE' $datafile`);
$simdir=~s/SIMTYPE\s+:\s+//;
$simdir.='-'.$datafile;
$simdir=~s/\.data$//;

my %simdata=(
'_DATAFILE'=>$datafile,
'_USER'=>$user,
'_LOCALHOST'=>$localhost,
'_RUNDIR'=>$rundir,
'_HOMEPATH'=>$homepath,
'_LOCALPATH'=>$localsynsimpath,
'_REMOTEPATH'=>$remotesynsimpath,
);

#to run SynSim on a remote machine:
my $templfilename="TEMPLATES/synsim_remote.templ";
if(not -e $templfilename) {
&create_template($templfilename);
}
my $scriptname="synsim_remote.pl";
open (PL,">$scriptname");
open (TEMPL, "<$templfilename")||die "Can't open $templfilename\n";
while (my $line = <TEMPL>) {

  foreach my $key (keys %simdata) {
    ($key!~/^_/) && next;
    $line =~ s/$key(?!\w)/$simdata{$key}/g;
  } # foreach 
  print PL $line;
} # while
close TEMPL;
close PL;

# In case we use NFS, we should not scp or rsync. 
#Simple check: create a file with the name of the localhost, and check for its existence over ssh
my $nfstest="$homepath/$localsynsimpath/$rundir/$localhost";
system("touch $nfstest");
#print STDERR qq(ssh $remotehost  perl -e \'if ( -e "$nfstest" ){print "0"}else{print "1"}\');die;
my $nonfs=`ssh $remotehost  "perl -e 'if ( -e qq($nfstest) ){print 0}else{print 1}'"`;
if($nonfs) {
#first time, or at start of run
#actually, the best way is to create synsim_remote.pl on the fly
system("scp $scriptname $remotehost:$scriptname");
#clean up;
unlink $scriptname;
#at start of synsim run
system("ssh $remotehost  perl $scriptname");
#after synsim run, collect the data
#system("rsync -uva ${remotehost}::home/$user/$remotesynsimpath/$rundir/$simdir .");
system("scp -C -r ${remotehost}:/local/home/$user/$remotesynsimpath/$rundir/$simdir .");
} else {
# In case of NFS homedir, it's simpler:
system("ssh $remotehost 'cd $homepath/$localsynsimpath/$rundir && ./synsim -p -f $datafile'");

}
} # END of run_on_remote_host 
#------------------------------------------------------------------------------
sub create_template {
my $templfilename=shift;
open(TEMPL,">$templfilename");
print TEMPL <<'ENDTEMPL';
#!/usr/bin/perl -w
use strict;

#to run SynSim on a remote machine:
#1. Needs a remote directory structure:
#-all relative to $homepath

my $datafile='_DATAFILE';
my $user='_USER';
my $localhost='_LOCALHOST';
my $rundir='_RUNDIR';
my $localsynsimpath='_LOCALPATH';
my $remotesynsimpath='_REMOTEPATH';
my $homepath='_HOMEPATH';
$remotesynsimpath=~s/^\///;
$remotesynsimpath=~s/\/$//;
my @pathparts=split('/',$remotesynsimpath);
$remotesynsimpath='';
chdir "$homepath";
foreach my $part (@pathparts){
$remotesynsimpath.="$part/";
if (not -d "$remotesynsimpath"){mkdir "$remotesynsimpath"};
}
chdir "$remotesynsimpath";

#Beware!
#This requires an rsync server with a module "home" on the local host;
#${localhost}::home/$user must correspond to $homepath!

system("rsync -uva  ${localhost}::home/$user/$localsynsimpath/Simulation .");

if (not -d "$rundir"){mkdir "$rundir" or die $!};
chdir "$rundir";
#system("rsync -uva  ${localhost}::home/$user/$localsynsimpath/$rundir/SOURCES .");
#system("rsync -uva  ${localhost}::home/$user/$localsynsimpath/$rundir/TEMPLATES .");
#system("rsync -uva  ${localhost}::home/$user/$localsynsimpath/$rundir/synsim .");
#system("rsync -uva  ${localhost}::home/$user/$localsynsimpath/$rundir/$datafile .");
system('scp -r -C ${localhost}:$homepath/$user/$localsynsimpath/$rundir/SOURCES .");
system('scp -r -C ${localhost}:$homepath/$user/$localsynsimpath/$rundir/TEMPLATES .");
system('scp -r -C ${localhost}:$homepath/$user/$localsynsimpath/$rundir/synsim .");
system('scp -r -C ${localhost}:$homepath/$user/$localsynsimpath/$rundir/$datafile .");
#now run synsim
system("./synsim -v -p -f $datafile");

#to get the results back, we'll scp from the other side

ENDTEMPL
}
#------------------------------------------------------------------------------
1;
