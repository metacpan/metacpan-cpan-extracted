package Parallel::Mpich::MPD::Common;

use strict;
use File::Temp;
use IO::All;
use Data::Dumper;
use Sys::Hostname;
=head1 NAME

Parallel::Mpich::MPD::Common - Mpich Common datas and fonctions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Olivier Evalet, Alexandre Masselot, C<< <alexandre.masselot at genebio.com> >>

=head1 EXPORT

=head3 $MPICH_HOME

mpich prefix (where it was installed). [default is empty, so mpich command shall be in the path]

=head1 FUNCTIONS

=head2 Environment

=head2 env_MpichHome([$val])

Get or set (if $val is defined) the Mpich home

=head2 env_Check

Check if mpd environment is correct

=head2 env_Print

print current environment

=head2 nbHostInMachinefile(machinesfile => $file)

return the nb hosts available on machinesfiles

=head2 commandPath($cmd)

prepend $MPICH_HOME/bin if $MPICH_HOME is defined and return the global command dstring

=head2 checkHosts(machinesfile => $machinesfile , hostsdown => \%hostsdown , hostsup =>\%hostsup)

 check hosts from machinesfile.
 - check hosts with a ping
 - check that ssh publickey is well configured
 
 
=head2 cleanTemp

  remove tmp files
  
=head2 __exec(cmd => $cmd, params => $params, [stdout=>\$stdout], [stderr=>\$stderr], [pid=>\$pid], [spawn=>$spawn=1])

extended exec that return the exit value and catch stds and pid.   

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
our %env;
our $MPICH_HOME=(defined $ENV{MPICH_HOME})?$ENV{MPICH_HOME}:"";
our $TMP_MPD_PREFIX="mpd-$ENV{USER}";
our $DEBUG=0;
our $WARN=0;
our $TEST=0;
our $ERROR_MSG;
our (@ISA, @EXPORT, @EXPORT_OK);
our @MPDBINS= qw(mpdlistjobs mpdcheck mpdboot mpdcleanup mpdtrace mpdringtest mpdallexit mpiexec);
@ISA        = qw(Exporter);
@EXPORT     = qw(%env env_MpichHome env_Init env_Check env_RPC env_User commandPath checkHosts stripMachinefile $ERROR_MSG $TMP_MPD_PREFIX);


@EXPORT_OK  = ();


#
# environment functions
#
sub env_MpichHome{ 
  my $val=shift;
  if(defined $val){
    $MPICH_HOME=$val;
  }
  return $MPICH_HOME;
}


sub commandPath{
  my $cmd=shift or die "must provide a command to commanPath";
  
  return $MPICH_HOME?$MPICH_HOME."/bin/$cmd":$cmd;
}
our $_isEnvInited;

sub env_Init{
  my %prms=@_;
  if($prms{reset}){
    undef %env;
    undef $_isEnvInited;
  }
  unless (defined $prms{root}){
    my $id=`id -u`;
    chop $id;
    die "ERROR: You must NOT run MPD as super user (root:$id)." if (!$TEST && $id==0 && defined $id);
  }
  return if $_isEnvInited;
  
  $env{path}=$MPICH_HOME?"$MPICH_HOME/bin":"";

  env_Hostsfile("$ENV{HOME}/mpd.hosts") unless $env{conf}{mpd}{hostsfile};
  
  #os info
  $env{info}{user}="$ENV{USER}";
  $env{info}{host}=hostname();
  #mpd informations
  $env{info}{ncpus}="0"     unless $env{info}{ncpus};
  $env{info}{listport}="0"  unless $env{info}{listport};
  $env{info}{ifhn}=""       unless $env{info}{ifhn};
  $_isEnvInited=1;
}

sub env_Check{
  my $stderr="";
  my $cpu="";
  env_Init();
  foreach (@MPDBINS){
    my $cmd=commandPath($_);
    unless(`$cmd -h`){
      $ERROR_MSG="ERROR:env_Check() cannot execute $cmd -h";
      goto err;
    }
  }
  unless($env{conf}{mpiexec}{ncpu}){
    $ERROR_MSG="ERROR:env_Check() empty number of cpu defined";
    goto err;
  }

  unless ( -e "$ENV{HOME}/.mpd.conf"){
    $ERROR_MSG="ERROR:env_Check() could not find \$HOME/.mpd.conf at : $ENV{HOME}/.mpd.conf";
    goto err;
  }
  
  return 1;
err:  
  Carp::cluck $ERROR_MSG if defined($ERROR_MSG);
  return 0;
}


#env_User([$user])
#  $user      specify the default user
sub env_User{
  my $user=shift;
  $env{info}{user}=$user;
  return $user;
}

sub env_Ncpu{
  my $ncpu=shift;
  $env{conf}{mpiexec}{ncpu}=$ncpu;
  return $ncpu;
}

#env_Hostsfile([$hostfile])
#  $hostfile     specify the default hostsfile for mpd
sub env_Hostsfile{
  my ($hostsfile)=@_;
#  Carp::cluck "HOST FILE=[$hostsfile]\n";
  return $env{conf}{mpd}{hostsfile} unless $hostsfile;

  print STDERR "ERROR: no $hostsfile" && return 0 unless -f $hostsfile;

  $env{conf}{mpd}{hostsfile}=$hostsfile;
  # the localhost should be added (could be a FIXME)
  $env{conf}{mpiexec}{ncpu}=nbHostInMachinefile($env{conf}{mpd}{hostsfile});
  return $env{conf}{mpd}{hostsfile};
}

sub nbHostInMachinefile{
  my $file=shift or die "must provide a file to ".__PACKAGE__.":nbHostInMachinefile()";
  my $hosts = io($file)->slurp;
  $hosts=~s/#.*$//gm;
  my @tmp=split(/\s*\n\s*/, $hosts);
  my $count=@tmp;
  print "DEBUG:nbHostInMachinefile(1) input=$file return=$count\n" if $DEBUG==1;
  return $count;
}

sub stripMachinefile{
  my $file=shift or die "must provide a file to ".__PACKAGE__.":stripMachinefile()";
  my $hosts = io($file)->slurp;
  $hosts=~s/#.*$//gm;
  my @tmp=split(/\s*\n\s*/, $hosts);
  my %host;
  foreach my $h (@tmp){
    $host{$h}=1;
  }
  @tmp= keys %host;
  my $count=@tmp;
  
  my $fh = new File::Temp(UNLINK=>0, TEMPLATE => File::Spec->tmpdir."/$TMP_MPD_PREFIX-hosts-XXXX");
  foreach (@tmp){
    print $fh $_."\n";
  }
  
  print "DEBUG:stripMachinefile(1) input=$file return=$count, output=".$fh->filename."\n" if $DEBUG==1;
  return ($count,$fh->filename);
}

sub env_Print{
  env_Init();
  printf "%-20s : %s\n", "user", "$env{info}{user}";
  printf "%-20s : %s\n", "machinesfile", $env{conf}{mpd}{hostsfile};
  printf "%-20s : %s\n", "mpiexec.cpu", $env{conf}{mpiexec}{ncpu};
  
  printf "%-20s : %s\n", "mpd.cpu", $env{info}{ncpus};
  printf "%-20s : %s\n", "mpd.port", $env{info}{listport};
  printf "%-20s : %s\n", "mpd.master", $env{info}{host};
  printf "%-20s : %s\n", "mpd.ifhn", $env{info}{ifhn};
  
  printf "%-20s : %s\n", "mpd.home", $MPICH_HOME;
  foreach (@MPDBINS){
    printf "%-20s : %s\n", "mpd.command", $MPICH_HOME.commandPath($_);
  }
  return 1;
}

  

sub __param_buildHost{
  #FIXME: ca veut dire quoi, cette ligne?
  my @hosts=shift;
  if(@hosts){
    my $fh = new File::Temp(UNLINK=>!$ENV{DO_NOT_REMOVE_TEMPFILE}, TEMPLATE => File::Spec->tmpdir."/$TMP_MPD_PREFIX-hosts-XXXX");
#    $hosts=~s/\s+/\n/g;
    foreach (@hosts){
      print $fh $_."\n";
    }
    return $fh->filename;
  }
}

# Check hosts will :
#   - check up or down
#   - ssh publickey auth

# machinesfile => $machinesfile , hostsdown => \%hostsdown , hostsup =>\%hostsup
sub checkHosts{
  my %params=@_;
  env_Init();
  my $hosts;
  my $hostsfile=(defined $params{machinesfile})? $params{machinesfile}:$env{conf}{mpd}{hostsfile};
  my $cmdssh;
  my %hostsdown;
  my %hostsup;

  if (defined $hostsfile && -e $hostsfile ){
    print "DEBUG: checkHosts -> $hostsfile\n" if ($Parallel::Mpich::MPD::Common::DEBUG == 1);
    $hosts=io($hostsfile)->slurp;
    my $res;
    foreach (split/\n/, $hosts){
      next unless /\S/;
      next if /#.*$/;
      $cmdssh="LANG=POSIX ping -fq -c 1 -i200ms  $_ &>/dev/null && ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no $_ exit 33 &>/dev/null";
      $res=int( system("$cmdssh") / 256);
      print "INFO: sheck host on $_ \treturn :$res (33 for ok)\n" if $DEBUG==1; 
      print $cmdssh."\n\treturn:$res\n" if  ($Parallel::Mpich::MPD::Common::DEBUG == 1);
      
      if ("$res" eq "1" ){
        print "WARNING: Connection refused on host: $_\n" if ($Parallel::Mpich::MPD::Common::WARN == 1);
	$hostsdown{$_}=1;
        next;
      }
      
      #ssh errors == 255
      if ("$res" eq "255" ){
        print "WARNING: authentication method publickey is not working on host: $_\n" if ($Parallel::Mpich::MPD::Common::WARN == 1);
	$hostsdown{$_}=1;
        next;
      }
      #ssh publickey connexion ok == 33 
      $hostsup{$_}=1 if ("$res" eq "33" );
      
    }
    
    %{$params{hostsup}}  = %hostsup   if (defined $params{hostsup} );
    if (defined( keys %hostsdown)){
      %{$params{hostsdown}}=%hostsdown if defined $params{hostsdown};
      return %hostsup=();
    }
    print "INFO: authentication method publickey is working on all hosts." if ($Parallel::Mpich::MPD::Common::WARN == 1);
    return %hostsup;
  }    
  print STDERR "ERROR: mpd hostsfile is not configured \n";
  return %hostsup=();  
}


sub cleanTemp{
  my $tmp=File::Spec->tmpdir;
  die "ERROR:cleanTemp: tmp directory is not defined!" unless defined ($tmp);
  my $cmd="rm -rf $tmp/$TMP_MPD_PREFIX-*";
 return system($cmd)==0;
}

#
#{
#  cmd => $cmd, spawn => undef? , stdout => \$stdout, stderr => <$stderr, pid => \$pid 
#}
sub __exec{ 
  my %params=@_;
  my $fout = new File::Temp(UNLINK=>1, TEMPLATE => File::Spec->tmpdir."/$TMP_MPD_PREFIX-sout-XXXX");
  my $ferr = new File::Temp(UNLINK=>1, TEMPLATE => File::Spec->tmpdir."/$TMP_MPD_PREFIX-serr-XXXX");
  my $ret="";
  my $end= ($params{spawn})? " </dev/null & ":"";
  my $_out=(! $params{spawn} && defined($params{stdout}) )? " 1>".$fout->filename:"";
  my $_err=(! $params{spawn} && defined($params{stderr}) )? " 2>".$ferr->filename:"";
  my $p = fork();
  if ($p == 0) {

    print STDERR "DEBUG: ".__PACKAGE__."::__exec($params{cmd} ".$_out . $_err .$end.")\n" if ($DEBUG==1) or $params{verbose};
    exec($params{cmd} .$_out . $_err .$end) || return 1;
  } else {
    ${$params{pid}}=$p if (defined($params{pid}));
    if ($params{spawn}){
      return 0;
    }
    waitpid($p, 0);
    my $exitval=$?/256;
    print STDERR __PACKAGE__."(".__LINE__.")exitval=[$exitval][$?]\n" if ($DEBUG==1);
    if (defined($params{stdout})){
      ${$params{stdout}}=io($fout->filename)->slurp;
    }
    if (defined($params{stderr})){
      ${$params{stderr}}=io($ferr->filename)->slurp ;
    }
    $ret=$exitval;
  }
  return $ret;
}


# __exec($cmd,$stdout,$stderr) return exit code 
# sub __exec_old{ 
#   my ($cmd,$stdout,$stderr, $pid)=@_;
#   my $fout = new File::Temp(UNLINK=>1);
#   my $ferr = new File::Temp(UNLINK=>1);
#   my $ret=system("$cmd 1>".$fout->filename." 2>".$ferr->filename) >> 8;
#   io($fout->filename) > $$stdout;
#   io($ferr->filename) > $$stderr;
#   return $ret;
# }



END { }       # module clean-up code here (global destructor)

1;

__END__
