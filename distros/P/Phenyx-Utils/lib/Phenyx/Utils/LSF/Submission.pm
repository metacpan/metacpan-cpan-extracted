use strict;

package Phenyx::Utils::LSF::Submission;
require Exporter;
use Carp;

=head1 NAME

Phenyx::Utils::LSF::Submission

=head1 SYNOPSIS


=head1 DESCRIPTION

For all related to LSF system submission (linux only). Read configuration data from properties (can be deduced from Phenyx::Config::GlobalParam)

Conceptually, this module is able to

=over 4

=item deal with a local or remote lsf master (meaning that the lsf system is not force to be ran on your machine)

=item pass whatever argument to bsub command

=item pre/pos synchronize sub directories

=item synchronize file at regular interval during execution between node0 and lsf master (and back to your machine if lsf master is remote)

=item extract properties from a function pointer (see t/Phenyx/Submit/LSF.t)

=item deal with more than one lsf submission in the same working directory

=back

#LSF activity
lsf.active=1

#LSF master host from outside
lsf.master.hostname=phenyx@vit-prd.unil.ch
#LSF master host name from within the cluster
lsf.master.localHostname=frt
#lsf.master.shell=/bin/bash
lsf.queue.name=priority

lsf.mpich.nbnodes=3,4
lsf.mpich.wrapper=$LSF_BINDIR/pam -g 1 mpichp4_wrapper

lsf.extrasubcommand=-P phenyx
lsf.extrasubcommand+=-R "select[model=XeonEM64T34]"

lsf.sync.pre.node0.directories=working,tmp
lsf.sync.post.node0.directories=working
lsf.sync.continuous.node0.files=tmp:my-stderr.txt
lsf.refreshDelay=10


=head1 FUNCTIONS

=head3 isActive([$val]);

Returns if the LSF is to be launched (lsf.active property)

=head3 isAvailable();

Returns true if LSF system is possible on the lsf master (bsub binary is available)

=head3 mpichActive();

return if mpich features is activated from (mpich.active property)

=head3 propertyExtractionFunction(\&fct)

Set a function to extract properties

=head3  readProperty($)

Read a property (such as lsf.master.hostname)

=head1 METHODS

=head3 $lsfSub = Phenyx::Utils::LSF::Submission->new([\%h])

=head3 $lsfSub->id();

Returns the LSF job id from the submitted job (undef means the job has not yet been submitted (or no id has been returned)

=head3 listNodes([model=>str] [,type=str])

Returns a hash of available nodes ([for a given proc type & model ]) within the served lsf system. Data is based on the lsf lshosts command.

=head3 getQueues()

Returns a list of available queues

=head3 $lsfSub->directory($cat [, $val]);

Returns [or set] a directory (ex $cat=working, tmp...)

=head3 $lsfSub->newScriptTag();

If more than one lsf job is submitted from within a directory, we want to label them (to build exec & pre-exec scripts, stderr and stdout files for examples).
Such a tag is read parsing lsf.*.scripts files in the current working directory.

=head3 $lsfSub->scriptTag();

Returns the current scriptTag

=head3 $lsfSub->syncStart();

Synchronize files (if any) at start time

=head3 $lsfSub->syncContinuous();

Synchronize files (if any) continuously during execution (frequency based on phenyx.lsf.sync.continuous.delay property)

=head3 $lsfSub->syncEnd();

Synchronize files (if any) at finish time.

=head3 $lsfSub->buildExecScript($executionCmd);

Builds the script file to feed the LSF bsub command. Returns the script file name

=head3 $lsfSub->buildPreExecScript();

Builds the script to be executed prior to launch (-E option) if any. Returns the script file name or undef if no command is to be executed.

=head3  $lsfSub->anyFileContSync();

Returns if any file is to be synchronized

=head3 $lsfSub->buildSynchroScript();

Builds locally the script which will be executed to synchronize the files (lsf.sync.continuous... property) every refreshDelay this script has to be standalone and to quit whenever the job has finished.

Returns without doing nothing if the script already exist or if no file is to be synchronized.

=head3 $lsfSub->buildSynchroScriptCall();

Build a .sh file to call the file from buildSynchroScript with the correct arguments.

=head3 submitLSF();

Submit the current setup lsf script to the system

=head3 $lsfSub->shellProfile()

Returns the .profile file (with aliases and shell functions) from the lib files

=head3 $lsfSub->wait4End();

Waits for the job has finished. Returns 0 if OK

=head3 $lsfSub->masterExec();

If a phenyx.lsf.master.hostname exist, make a command to ssh all conmmands. If not, just execute locally.

=head3 $lsfSub->masterExecCmd($cmd);

Prepend an ssh string if the lsf master is remote

=head1 PROPERTIES

#lsf active (no effective lsf submission if not active)
lsf.active=0|1
#lsf master hostname, to be contacted from outside the cluster
#nothing means lsf master is the localhost
lsf.master.hostname=host
#lsf master hostname, contacted from within the cluster
lsf.master.localHostname=host
#queue to to submited (bsub -q argument)
lsf.queue.name=name
#/bin/bash by default (bsub -L argument)
lsf.master.shell=shell path
#nb nodes for mpich submission (bsub -n arg)
lsf.mpich.nbnodes=n[,m]
#mpich wrapper command
lsf.mpich.wrapper=string
#extra param to be passed to bsub
lsf.extrasubcommand=multiline string

#registered directories to be synchronized beteween master and node0 before the job starts
lsf.sync.pre.node0.directories=dir1[,dir2]
#after the job has finsished
lsf.sync.post.node0.directories=dir1[,dir2[...]]
#files to be kept updated back on the master every refreshDelay seconds
lsf.sync.continuous.node0.files=dir1:file1,[dir2:file2[...]]
lsf.sync.refreshDelay=int [10 default]


=head1 EXAMPLES


=head1 SEE ALSO

Phenyx::Submit::JobSubmission, Phenyx::Config::GlobalParam

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com


=cut

use Phenyx::Utils::LSF::JobInfo;

use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use File::Path;
use File::Find::Rule;
use File::chmod;
use File::Copy;

use POSIX ":sys_wait_h";
use Errno qw(EAGAIN);

use Time::localtime;
use File::Basename;
use Cwd qw(getcwd);

our (@ISA,@EXPORT,@EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = ();

our $rsyncCmdHead="rsync --recursive --verbose --rsh=ssh";
#a pointer to a function to extract properties
our $propExtractFct;

sub new{
  my ($pkg, $h)=@_;

  my $dvar={};
  bless $dvar, $pkg;

  foreach (keys %$h){
    $dvar->set($_, $h->{$_});
  }

  $dvar->{active}=readProperty('lsf.active');

  $dvar->{master}{hostname}=readProperty('lsf.master.hostname');
  $dvar->{master}{localHostname}=readProperty('lsf.master.localHostname');
  $dvar->{queue}{name}=readProperty('lsf.queue.name');
  $dvar->{master}{shell}=readProperty('lsf.master.shell') || '/bin/bash';
  $dvar->{mpich}{nbnodes}=readProperty('lsf.mpich.nbnodes');
  $dvar->{mpich}{wrapper}=readProperty('lsf.mpich.wrapper');

  my @tmp=readProperty('lsf.extrasubcommand');
  $dvar->{extrasubcommand}=\@tmp;

  $dvar->{sync}{pre}{node0}{directories}=readProperty('lsf.sync.pre.node0.directories');
  $dvar->{sync}{post}{node0}{directories}=readProperty('lsf.sync.post.node0.directories');
  $dvar->{sync}{continuous}{node0}{files}=readProperty('lsf.sync.continuous.node0.files');
  $dvar->{sync}{refreshDelay}=readProperty('lsf.sync.refreshDelay')||10;

  return $dvar;
}


##### global function

sub isActive{
  my $this=shift;
  my $val=shift;
  if(defined $val){
    $this->{active}=$val;
  }
  return $this->{active};
}

sub propertyExtractionFunction{
  my $fct=shift;
  croak __PACKAGE__.": propertyExtractionFunction() has not been defined" if((! defined $fct) && (!defined $propExtractFct));
  $propExtractFct=$fct if defined $fct;
  return $propExtractFct
}

sub readProperty($){
  return propertyExtractionFunction()->(shift);
}

#### master sub

sub listNodes{
  my $this=shift;
  my %prm=@_;
  my %ctr;
  $ctr{model}=$prm{model};
  $ctr{type}=$prm{type};

  my $cmd=$this->masterExecCmd('lshosts');
  my $fd;
  open ( $fd, "$cmd|") or croak "cannot launch command $cmd: $!";
  $_=<$fd>;
  my @headers=split;
  my %list;
  while (<$fd>){
    chomp;
    my @line=split /\s+/, $_, scalar(@headers);
    my $host=$line[0];
    foreach (0..$#headers){
      $list{$host}{$headers[$_]}=$line[$_];
    }
  }
  foreach my $ctr (qw/model type/){
    next unless $ctr{$ctr};
    foreach (keys %list){
      delete $list{$_} unless  $list{$_}->{$ctr} =~ /$ctr{$ctr}/;
    }
  }
  return %list;
}

sub masterExecCmd{
  my $this=shift;
  my $cmdExec="@_";

  my $cmd;
  undef $cmd;
  $cmd="ssh $this->{master}{hostname} " if $this->{master}{hostname};
  $cmd.=$cmdExec;
  return $cmd;
}

sub masterExec{
  my $this=shift;
  my $cmd=$this->masterExecCmd(@_);

  system "$cmd" && croak "error executing line $cmd";
}

###############

sub newScriptTag{
  my $this=shift;
  my @files=File::Find::Rule->file()->name('lsf.*.script.sh')->in('.');
  my $max=-1;
  foreach (@files){
    die "cannot parse [$_] for a tag" unless /lsf\.(.+)\.script.sh/;
    $max=$1 if $1>$max;
  }
  $max++;
  $this->{scriptTag}=$max;
  my $fd;
  open ($fd, ">lsf.$this->{scriptTag}.script.sh");
  close $fd;
  return $this->{scriptTag};
}

sub scriptTag{
  my $this=shift;
  $this->newScriptTag() unless defined $this->{scriptTag};
  return $this->{scriptTag};
}

############### Accessors/Setters


sub directory{
  my($this, $cat, $val)=@_;
  croak "a cat parameter ('working', 'tmp'...) must be defined in lsfSub->directory() method" unless defined $cat;
  if(defined $val){
    $this->{directories}{$cat}=$val;
  }
  return $this->{directories}{$cat};
}

sub mpichActive{
  my($this, $val)=@_;
  if(defined $val){
    $this->{mpich}{active}=$val;
  }
  return $this->{mpich}{active};
}

###############

sub buildExecScript{
  my $this=shift;
  my $cmd=shift;

  croak "could not define script tag" unless defined $this->scriptTag();

  my $fname=getcwd."/lsf.$this->{scriptTag}.script.sh";
  my $fdout;
  open ($fdout, ">$fname") or croak "cannot open [$fname] for writing: $!";

  my $fdin;
  open ($fdin, "<".$this->shellProfile()) or die "cannot open profile def [".$this->shellProfile()."] for reading: $!";
  print $fdout "#start --- include profile from ".$this->shellProfile()."\n";
  while (<$fdin>) {
    print $fdout $_;
  }
  print $fdout "#end --- including profile from ".$this->shellProfile()."\n";

  my $lsftag=$this->{scriptTag};
  $this->{stdout} ||= "$this->{directories}{working}/lsf.$lsftag.stdout";
  $this->{stderr} ||= "$this->{directories}{working}/lsf.$lsftag.stderr";
  print $fdout <<EOT;
#!$this->{master}{shell}
#BSUB -L $this->{master}{shell}
#BSUB -q $this->{queue}{name}
#BSUB -o $this->{stdout}
#BSUB -e $this->{stderr}
EOT
  if(ref($this->{extrasubcommand}) eq 'ARRAY'){ 
    foreach (@{$this->{extrasubcommand}}){
      print $fdout "#BSUB $_\n";
     }
  }else{
      print $fdout "#BSUB $this->{extrasubcommand}\n";
  }
  #post synchronize stdout & stderr if those file exist
  foreach (qw /stdout stderr/){
    if(-e dirname($this->{$_})){
      print $fdout "#BSUB -f \"$this->{$_} ><\"\n";
    }
  }

  my $preExec=$this->buildPreExecScript();
  my $tmpPreExec;
  if ($preExec){
    $tmpPreExec=$preExec;
    $tmpPreExec=~s/\//_/g;
    $tmpPreExec="/tmp/$tmpPreExec";
    #    copy($preExec, $tmpPreExec) or die "cannot copy($preExec, $tmpPreExec): $!";
    print $fdout "#BSUB -E \"rsync $this->{master}{localHostname}:$preExec $tmpPreExec; $tmpPreExec\"\n";

    if($this->mpichActive() && (split ',', $this->{mpich}{nbnodes})[0]>1){
      print $fdout "#BSUB -n $this->{mpich}{nbnodes}\n";
      $cmd="$this->{mpich}{wrapper} $cmd";
    }
    print $fdout "\n$cmd\n\n";
    #print $fdout "\nrm $tmpPreExec\n\n";
  }

  print $fdout "#post sync commands\n";
  foreach (split /,/, $this->{sync}{post}{node0}{directories}) {
    my $dn=dirname($this->directory($_));
    my $cmd="$rsyncCmdHead ".$this->directory($_)." $this->{master}{localHostname}:$dn/";
    print $fdout "$cmd\n";
  }

  $this->{script}=$fname;
  chmod("a+x", $fname);
  return $this->{script};
}

sub buildPreExecScript{
  my $this=shift;

  croak "could not define script tag" unless defined $this->scriptTag();

  my $fname=getcwd."/lsf.$this->{scriptTag}.pre-script.sh";
  my $fdout;
  open ($fdout, ">$fname") or croak "cannot open [$fname] for writing: $!";

  my $usePreExec;
  my $fdin;
#  open ($fdin, "<".$this->shellProfile()) or die "cannot open profile def [".$this->shellProfile()."] for reading: $!";
#  print $fdout "#start --- include profile from ".$this->shellProfile()."\n";
#  while (<$fdin>){
#    print $fdout $_;
#  }
#  print $fdout "#end --- including profile from ".$this->shellProfile()."\n";

  foreach (split /,/, $this->{sync}{pre}{node0}{directories}){
    my $cmd="mkdir -p ".dirname($this->directory($_))."; $rsyncCmdHead $this->{master}{localHostname}:".$this->directory($_)." ".dirname($this->directory($_))."/";
    print $fdout "$cmd\n";
    $usePreExec=1;
  }
  close $fdout;

  if($usePreExec){
    $this->{preExecScript}=$fname;
    chmod("a+x", $fname);
    return $this->{preExecScript};
  }else{
    unlink $fname;
    return undef;
  }
}

sub buildSynchroScript{
  my $this=shift;

  return unless $this->{sync}{continuous}{node0}{files};
  return $this->{contSynchroScript} if -f $this->{contSynchroScript};

  my $JobInfoPMFile=dirname(__FILE__)."/JobInfo.pm";
  my $fd;
  open ($fd, "<$JobInfoPMFile") or die "cannot open for read $JobInfoPMFile: $!";
  local $/;
  my $pmContents=<$fd>;
  close $fd;
  eval{
    eval Pod::Strip;
    my $p=Pod::Strip->new;
    my $tmp=$pmContents;
    undef $pmContents;
    $p->output_string(\$pmContents);
    $p->parse_string_document($tmp);
  };
  if($@){
    warn "[warning] could not strip Pod from $JobInfoPMFile. $!";
  }


  $ENV{PATH}.=":".dirname(__FILE__)."/../../../../scripts/";
  my $synchroScript=`which lsf-synchroFilesUntilFinished.pl` or die "cannot find executable script lsf-synchroFilesUntilFinished.pl in $ENV{PATH}";
  open ($fd, "<$synchroScript") or die "cannot open for read $synchroScript: $!";
  my $scriptContent=<$fd>;
  close $fd;
  $scriptContent=~s/use\s+Phenyx::Utils::LSF::JobInfo;/$pmContents\n/ or die "could not patch line use\\s+Phenyx::Utils::LSF::JobInfo; in script $synchroScript";

  my $script=getcwd."/lsf.contsynchro-script.pl";
  open ($fd, ">$script") or die "cannot open for writing $script: $!";
  print $fd $scriptContent;
  close $fd;
  $this->{contSynchroScript}=$script;
  chmod "+x", $script;
  return $this->{contSynchroScript};
}

sub buildSynchroScriptCall{
  my $this=shift;

  my $script=getcwd."/lsf.$this->{scriptTag}.contsynchro-call-script.sh";
  return $script if -f $script;

  unless(Phenyx::Utils::LSF::JobInfo::isJobRunning($this->{lsfid})){
    die "cannot buildSynchroScriptCall for LSF job [$this->{lsfid}] as it is not yet running";
  }

  my $synchroFiles;
  foreach(split /,/, $this->{sync}{continuous}{node0}{files}){
    my ($d, $f)=split /:/, $_;
    $synchroFiles.=" $this->{directories}{$d}/$f"
  }
  unless($synchroFiles){
      undef $this->{contSynchroScriptCall};
      return undef;
  }

  my $fd;
  open ($fd, ">$script") or die "cannot open for writing $script: $!";
  if ($this->{master}{hostname}){
      my $rsync="$rsyncCmdHead $this->{contSynchroScript}  $this->{master}{hostname}:$this->{contSynchroScript} ";
      #copy script call to remote
      print $fd "$rsync\n";
      # make a remote call to execute the files between node0 and lsf master
      my $cmd="ssh -n $this->{master}{hostname} '$this->{contSynchroScript} --rsyncopt=\"--rsh=ssh\" --lsfid=$this->{lsfid} --remotenode=0 $synchroFiles' &";
      print $fd "$cmd\n";
      sleep 2;
      #make a call to synchronize between lsf master and local
      $cmd="$this->{contSynchroScript} --rsyncopt=\"--rsh=ssh\" --lsfhost=$this->{master}{hostname} --lsfid=$this->{lsfid} --remotehost=$this->{master}{hostname} $synchroFiles";
      print $fd "$cmd\n";

      foreach (split /,/, $this->{sync}{post}{node0}{directories}) {
	my $dn=dirname($this->directory($_));
	my $cmd="$rsyncCmdHead $this->{master}{hostname}:".$this->directory($_)." $dn/";
	print $fd "$cmd\n";
      }
  }else{
      print $fd "$this->{contSynchroScript} --rsyncopt='--rsh=ssh' --lsfid=$this->{lsfid} --remotenode=0 $synchroFiles\n";
  }
  close $fd;

  $this->{contSynchroScriptCall}=$script;
  chmod "+x", $script;
  return $this->{contSynchroScriptCall};
}

sub submitLSF{
  my $this=shift;
  die "cannot submitLSF if buildExecScript has not been created [$this->{script}]" unless -f $this->{script};
  die "cannot submit if {basedir} attribute was not set to lsfSubbmission opbject" unless  $this->{basedir};

  if ($this->{master}{hostname}) {
    my $cmd="scp -r $this->{basedir} $this->{master}{hostname}:".(dirname $this->{basedir})."/";
    system($cmd) && die "could not execute [$cmd]: $!";
    $Phenyx::Utils::LSF::JobInfo::SHELLCOMMANDPREFIX="ssh $this->{master}{hostname}";
  }


  my $cmd=$this->masterExecCmd("bsub <$this->{script}");
  my $fd;
  open ($fd, "$cmd|") or die "cannot open pipe from [$cmd]";
  my $line=<$fd>;
  chomp $line;
  die "cannot extract LSF job id from line [$line]" unless $line=~/Job <(\d+)> is submitted/;
  $this->{lsfid}=$1;
  close $fd;
  my $whiled;
  while(!(Phenyx::Utils::LSF::JobInfo::isJobRunning($this->{lsfid}) or Phenyx::Utils::LSF::JobInfo::isJobFinished($this->{lsfid}))){
    print STDERR ".";
    $whiled=1;
    sleep 1;
  }
  print STDERR "\n" if $whiled;
  if(my $f=$this->buildSynchroScriptCall()){
    system($f) && die "canot execute [$f]: $!";
  }

}

sub shellProfile{
  my $this=shift;
  my $prf=dirname(__FILE__)."/lsf.".basename($this->{master}{shell}).".profile";
  return $prf
}

1;
