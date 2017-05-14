#!/usr/bin/env perl
use strict;
use Test::More tests=>13;

use_ok('Phenyx::Utils::LSF::Submission');
use File::Temp qw(tempdir);

use File::Basename;
use Cwd qw(getcwd);
my $dn=getcwd $0;

initGetProp();

my $lsfSub=new Phenyx::Utils::LSF::Submission;
unless ($lsfSub->isActive()){
 SKIP:{
    skip "LSF is not active", 1;
  }
} else {
  my %nodes=$lsfSub->listNodes();
  ok(%nodes, "nodes list (".(scalar keys %nodes).") retrieved");
  #  my %nodes=$lsfSub->listNodes(model=>'XeonEM64');
  #  ok(%nodes, "nodes list (".(scalar keys %nodes).") retrieved");

  my $tmpdir=tempdir(CLEANUP=>0, UNLINK=>0);
  print STDERR "tmpdir is [$tmpdir]\n";
  $lsfSub->{basedir}=$tmpdir;
  chdir $tmpdir or die "cannot chdir to temp dir $tmpdir";

  mkdir "working";
  $lsfSub->directory("working", "$tmpdir/working");

  mkdir "tmp";
  $lsfSub->directory("tmp", "$tmpdir/tmp");

  my $tag0=$lsfSub->newScriptTag();
  ok(defined $tag0, "new script tag [$tag0] defined");
  #   my $tag0=$lsfSub->newScriptTag();
  #   ok(defined $tag0, "new script tag [$tag0] defined");
  is($tag0, $lsfSub->scriptTag(), "script tag is correctly stored");

  my $prf=$lsfSub->shellProfile();
  ok(-e $prf, "shell profile file [$prf] exist");
  ok(-r $prf, "shell profile file [$prf] readable");

  $lsfSub->mpichActive(1);
  my $cmd=<<EOT;
/mnt/local/phenyx/lsf/bin/mpibasictest;
perl -e 'foreach (1..35){print STDERR "\$_\\n"; sleep 1}' 2>$tmpdir/tmp/my-stderr.txt
EOT

  my $script=$lsfSub->buildExecScript('/mnt/local/phenyx/lsf/bin/mpibasictest; perl ');

  $Phenyx::Utils::LSF::JobInfo::CHEAT_BJOBS_COMMAND="cat $dn/bjobs.out";
  $lsfSub->{lsfid}='850381';

  my $pl=$lsfSub->buildSynchroScript();
  ok(-e $pl, "synchroscript exist [$pl]");
  ok(-x $pl, "synchroscript executable [$pl]");
  #tweak with demo file;
  my $sh=$lsfSub->buildSynchroScriptCall();
  ok(-e $sh, "synchroscriptCall exist [$sh]");
  ok(-e $sh, "synchroscriptCall executable [$sh]");

  $lsfSub->newScriptTag();
  undef $Phenyx::Utils::LSF::JobInfo::CHEAT_BJOBS_COMMAND;
  my $script=$lsfSub->buildExecScript($cmd);
  $lsfSub->{sync}{continuous}{node0}{files}='tmp:my-stderr.txt';
  #echo "PROUTOUTOUT"'."\n".'echo "POUET"');
  #we do must copy all files on the lsf mast if it is remote
  $lsfSub->submitLSF();
  ok($lsfSub->{lsfid}, "submitted lsf job [$lsfSub->{lsfid}]");
  ok(-e $sh, "synchroscriptCall exist [$sh]");
  ok(-e $sh, "synchroscriptCall executable [$sh]");
}


my %tProp;
sub initGetProp(){
  eval{
    require Phenyx::Config::GlobalParam;
    warn "using Phenyx::Config::GlobalParam properties to setup $0";
    Phenyx::Config::GlobalParam::readParam();
    Phenyx::Utils::LSF::Submission::propertyExtractionFunction(\&getPropFromGlobalParam);
  };
  if($@){
    warn "[warning] no phenyx env defined, reading from local prop file";
    my $propFile=dirname($0)."/lsf.conf";
    open (fd, "<$propFile") or die "cannot open for reading [$propFile]; $!";
    while(<fd>){
      next if /^#/;
      next unless /(.*?)=(.*)/;
      my ($n, $v)=($1, $2);
      if ($n=~s/\+$//){
	  if((ref $tProp{$n}) eq 'ARRAY'){
	      push @{$tProp{$n}}, $v;
	  }else{
	      $tProp{$n}=[$tProp{$n}, $v];
	  }
      }else{
	$tProp{$n}=$v;
      }
    }
    Phenyx::Utils::LSF::Submission::propertyExtractionFunction(\&getPropFromTProp);
  }
}

sub getPropFromGlobalParam($){
  my $arg=shift;
  return Phenyx::Config::GlobalParam::get("phenyx.$arg");
}

sub getPropFromTProp($){
  my $arg=shift;
  if(ref($tProp{$arg})eq 'ARRAY'){
      return @{$tProp{$arg}};
  }else{
      return $tProp{$arg};
  }
}
