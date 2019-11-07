package Proc::Background::Unix;
$Proc::Background::Unix::VERSION = '1.21';
# ABSTRACT: Unix-specific implementation of process create/wait/kill
require 5.004_04;

use strict;
use Exporter;
use Carp;
use POSIX qw(:errno_h :sys_wait_h);

@Proc::Background::Unix::ISA = qw(Exporter);

# Start the background process.  If it is started sucessfully, then record
# the process id in $self->{_os_obj}.
sub _new {
  my $class = shift;

  unless (@_ > 0) {
    confess "Proc::Background::Unix::_new called with insufficient number of arguments";
  }

  return unless defined $_[0];

  # If there is only one element in the @_ array, then it may be a
  # command to be passed to the shell and should not be checked, in
  # case the command sets environmental variables in the beginning,
  # i.e. 'VAR=arg ls -l'.  If there is more than one element in the
  # array, then check that the first element is a valid executable
  # that can be found through the PATH and find the absolute path to
  # the executable.  If the executable is found, then replace the
  # first element it with the absolute path.
  my @args = @_;
  if (@_ > 1) {
    $args[0] = Proc::Background::_resolve_path($args[0]) or return;
  }

  my $self = bless {}, $class;

  # Fork a child process.
  my $pid;
  {
    if ($pid = fork()) {
      # parent
      $self->{_os_obj} = $pid;
      $self->{_pid}    = $pid;
      last;
    } elsif (defined $pid) {
      # child
      exec @_ or croak "$0: exec failed: $!\n";
    } elsif ($! == EAGAIN) {
      sleep 5;
      redo;
    } else {
      return;
    }
  }

  $self;
}

# Wait for the child.
#   (0, exit_value)	: sucessfully waited on.
#   (1, undef)	: process already reaped and exit value lost.
#   (2, undef)	: process still running.
sub _waitpid {
  my ($self, $blocking, $wait_seconds) = @_;

  {
    # Try to wait on the process.
    # Implement the optional timeout with the 'alarm' call.
    my $result= 0;
    if ($blocking && $wait_seconds) {
      require Time::HiRes;
      local $SIG{ALRM}= sub { die "alarm\n" };
      Time::HiRes::alarm($wait_seconds);
      eval { $result= waitpid($self->{_os_obj}, 0); };
      Time::HiRes::alarm(0);
    }
    else {
      $result= waitpid($self->{_os_obj}, $blocking? 0 : WNOHANG);
    }

    # Process finished.  Grab the exit value.
    if ($result == $self->{_os_obj}) {
      return (0, $?);
    }
    # Process already reaped.  We don't know the exist status.
    elsif ($result == -1 and $! == ECHILD) {
      return (1, 0);
    }
    # Process still running.
    elsif ($result == 0) {
      return (2, 0);
    }
    # If we reach here, then waitpid caught a signal, so let's retry it.
    redo;
  }
  return 0;
}

sub _die {
  my $self = shift;
  my @kill_sequence= @_ && ref $_[0] eq 'ARRAY'? @{ $_[0] } : qw( TERM 2 TERM 8 KILL 3 KILL 7 );
  # Try to kill the process with different signals.  Calling alive() will
  # collect the exit status of the program.
  while (@kill_sequence and $self->alive) {
    my $sig= shift @kill_sequence;
    my $delay= shift @kill_sequence;
    kill($sig, $self->{_os_obj});
    last if $self->_reap(1, $delay); # block before sending next signal
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::Background::Unix - Unix-specific implementation of process create/wait/kill

=head1 VERSION

version 1.21

=head1 SYNOPSIS

Do not use this module directly.

=head1 DESCRIPTION

This is a process management class designed specifically for Unix
operating systems.  It is not meant used except through the
I<Proc::Background> class.  See L<Proc::Background> for more information.

=head1 NAME

Proc::Background::Unix - Unix interface to process management

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
