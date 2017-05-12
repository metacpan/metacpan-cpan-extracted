# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::Processes::Base;

use warnings;
use strict;

# Inheritance
our @ISA = qw();

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
}

# "Virtual" methods
# 
# $status = $self->process_run($cmd,$out_log)
# $process_info_str = $self->process_spawn($cmd,$out_log)
# $is_running = $self->process_running($process_info_str)
# $status = $self->process_result($process_info_str)

########################################################################

package SOAP::Clean::Processes::Basic;

use warnings;
use strict;

use POSIX ":sys_wait_h";
use File::Temp qw/ :POSIX /;

use SOAP::Clean::Misc;

our @ISA = qw(SOAP::Clean::Processes::Base);

sub initialize {
  my ($self) = @_;
  $self->SUPER::initialize();
}

########################################################################

sub process_run {
  my ($self,$cmd,$out_log) = @_;

  my $extended_cmd =
    sprintf("sh -c '( %s ) < /dev/null > %s 2>&1'", 
	    $cmd, $out_log);
  my $status = system($extended_cmd);
  return $status;
}

########################################################################

sub process_spawn {
  my ($self,$cmd,$out_log) = @_;

  my $status_file = tmpnam();
  my $extended_cmd =
    sprintf("sh -c '( %s ) < /dev/null > %s 2>&1; echo \$? > %s'", 
	    $cmd, $out_log, $status_file);
  # Spawn the command.
  my $pid = fork();
  if (!defined($pid)) {
    die("SOAP-Server - fork failed");
  } elsif ($pid == 0) {
    # the child we have to close all files, or Apache will wait for the
    # child to finish.
    close(STDIN); close(STDOUT); close(STDERR);
    exec($extended_cmd);
    die; # if we reach this, then the exec failed.
  }

  my $process_info = [ $pid, $status_file ];
  my $process_info_str = basic_info_to_string($process_info);
  return $process_info_str;
}

########################################################################

sub process_running {
  my ($self,$process_info_str) = @_;
  my $process_info = basic_info_from_string($process_info_str);
  my ($pid,$status_file) = @$process_info;

  # First, try waitpid. This will succeed if the process is a child of
  # the current process. waitpid is horrendously slow under Cygwin. It
  # seems to run reasonably under Linux.
  my $waitpid_result = waitpid($pid,WNOHANG);
  if ( $waitpid_result == 0 ) {
    # still running.
    return 1;
  } elsif ( $waitpid_result == $pid ) {
    # done.
    return 0;
  }

  # Walk the process table
  open F,"ps -aef |";

  # Find the index of the PID field.
  my $l = <F> || die;
  chomp $l;
  $l =~ s/^[ \t]+//;
  my @fields = split(/[ \t]+/,$l);
  my $i = 0;
  my $found_pid = 0;
 FIELD:
  foreach my $f ( @fields ) {
    if ($f eq "PID") { 
      $found_pid = 1;
      last FIELD; 
    }
    $i++;
  }
  $found_pid || die;


  # Look for the $pid in the PID field.
  my $result = 0;
 LINE:
  while ($l = <F>) {
    chomp $l;
    $l =~ s/^[ \t]+//;
    @fields = split(/[ \t]+/,$l);
    if ($fields[$i] == $pid) {
      # still running!
      $result = 1;
      last LINE;
    }
  }

  close F;
  return $result;
}

########################################################################

sub process_result {
  my ($self,$process_info_str) = @_;
  my $process_info = basic_info_from_string($process_info_str);
  my ($pid,$status_file) = @$process_info;

  # The process had better be done!
  (!$self->process_running($process_info)) || die;

  if ( ! ( -r $status_file ) ) { return -1; }

  open F,"<$status_file" || die;
  my $status = <F>;
  close F;

  unlink $status_file;

  return $status;
}

########################################################################

sub basic_info_to_string {
  my ($process_info) = @_;

  if ( !(ref $process_info) ) { return $process_info; }

  my ($pid,$status_file) = @$process_info;

  return sprintf("%d:%s",$pid,$status_file);
}

########################################################################

sub basic_info_from_string {
  my ($str) = @_;

  if ( ref $str eq "ARRAY" ) { return $str; }

  assert($str =~ /([0-9]+):(.*)/ );

  return [ $1, $2 ];
}

########################################################################

1;
