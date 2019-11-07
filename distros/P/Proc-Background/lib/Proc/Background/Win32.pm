package Proc::Background::Win32;
$Proc::Background::Win32::VERSION = '1.21';
# ABSTRACT: Windows-specific implementation of process create/wait/kill
require 5.004_04;

use strict;
use Exporter;
use Carp;
use Win32::Process qw( NORMAL_PRIORITY_CLASS INFINITE );
use Win32::ShellQuote ();

@Proc::Background::Win32::ISA = qw(Exporter);

sub _new {
  my $class = shift;

  unless (@_ > 0) {
    confess "Proc::Background::Win32::_new called with insufficient number of arguments";
  }

  return unless defined $_[0];

  # If there is only one argument, treat it as system() would and assume
  # it should be split into arguments.  The first argument is then the
  # application executable.
  my ($exe, $cmdline);
  if (@_ == 1) {
    $cmdline= $_[0];
    ($exe) = Win32::ShellQuote::unquote_native($cmdline);
  }
  # system() would treat a list of arguments as an un-quoted ARGV
  # for the program, so concatenate them into a command line appropriate
  # for Win32 CommandLineToArgvW to decode back to what we started with.
  # Preserve the first un-quoted argument for use as lpApplicationName.
  else {
    $exe = $_[0];
    $cmdline= Win32::ShellQuote::quote_native(@_);
  }

  # Find the absolute path to the program.  If it cannot be found,
  # then return.  To work around a problem where
  # Win32::Process::Create cannot start a process when the full
  # pathname has a space in it, convert the full pathname to the
  # Windows short 8.3 format which contains no spaces.
  $exe = Proc::Background::_resolve_path($exe) or return;
  $exe = Win32::GetShortPathName($exe);

  my $self = bless {}, $class;

  # Perl 5.004_04 cannot run Win32::Process::Create on a nonexistant
  # hash key.
  my $os_obj = 0;

  # Create the process.
  if (Win32::Process::Create($os_obj,
			     $exe,
			     $cmdline,
			     0,
			     NORMAL_PRIORITY_CLASS,
			     '.')) {
    $self->{_pid}    = $os_obj->GetProcessID;
    $self->{_os_obj} = $os_obj;
    return $self;
  } else {
    return;
  }
}

# Reap the child.
#   (0, exit_value)	: sucessfully waited on.
#   (1, undef)	: process already reaped and exit value lost.
#   (2, undef)	: process still running.
sub _waitpid {
  my ($self, $blocking, $wait_seconds) = @_;

  # Try to wait on the process.
  my $result = $self->{_os_obj}->Wait($wait_seconds? int($wait_seconds * 1000) : $blocking ? INFINITE : 0);
  # Process finished.  Grab the exit value.
  if ($result == 1) {
    my $exit_code;
    $self->{_os_obj}->GetExitCode($exit_code);
    if ($exit_code == 256 && $self->{_called_terminateprocess}) {
      return (0, 9); # simulate SIGKILL exit status
    } else {
      return (0, $exit_code<<8);
    }
  }
  # Process still running.
  elsif ($result == 0) {
    return (2, 0);
  }
  # If we reach here, then something odd happened.
  return (0, 1<<8);
}

sub _die {
  my $self = shift;
  my @kill_sequence= @_ && ref $_[0] eq 'ARRAY'? @{ $_[0] } : qw( TERM 2 TERM 8 KILL 3 KILL 7 );

  # Try the kill the process several times.
  # _reap will collect the exit status of the program.
  while (@kill_sequence and $self->alive) {
    my $sig= shift @kill_sequence;
    my $delay= shift @kill_sequence;
    $sig eq 'KILL'? $self->_send_sigkill : $self->_send_sigterm;
    last if $self->_reap(1, $delay); # block before sending next signal
  }
}

# Use taskkill.exe as a sort of graceful SIGTERM substitute.
sub _send_sigterm {
  my $self = shift;
  # TODO: This doesn't work reliably.  Disabled for now, and continue to be heavy-handed
  # using TerminateProcess.  The right solution would either be to do more elaborate setup
  # to make sure the correct taskkill.exe is used (and available), or to dig much deeper
  # into Win32 API to enumerate windows or threads and send WM_QUIT, or whatever other APIs
  # processes might be watching on Windows.  That should probably be its own module.
  # my $pid= $self->{_pid};
  # my $out= `taskkill.exe /PID $pid`;
  # If can't run taskkill, fall back to TerminateProcess
  # $? == 0 or
  $self->_send_sigkill;
}

# Win32 equivalent of SIGKILL is TerminateProcess()
sub _send_sigkill {
  my $self = shift;
  $self->{_os_obj}->Kill(256);  # call TerminateProcess, essentially SIGKILL
  $self->{_called_terminateprocess} = 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::Background::Win32 - Windows-specific implementation of process create/wait/kill

=head1 VERSION

version 1.21

=head1 SYNOPSIS

Do not use this module directly.

=head1 DESCRIPTION

This is a process management class designed specifically for Win32
operating systems.  It is not meant used except through the
I<Proc::Background> class.  See L<Proc::Background> for more information.

=head1 NAME

Proc::Background::Win32 - Interface to process management on Win32 systems

=head1 IMPLEMENTATION

This package uses the Win32::Process class to manage the objects.

=head1 AUTHORS

=over 4

=item *

Blair Zajac <blair@orcaware.com>

=item *

Michael Conrad <mike@nrdvana.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad, (C) 1998-2009 by Blair Zajac.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
