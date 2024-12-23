package Proc::Forkmap;
use POSIX qw(:sys_wait_h);
use Proc::Fork;
use Carp;
use IO::Pipe;
use strict;
use warnings;
use 5.010;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(forkmap);

our $MAX_PROCS = 4;
our $VERSION = '0.2100';
our $TIMEOUT = 0;

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->_init;
  return $self;
}

sub _init {
  my $self = shift;
  $self->{max_procs} //= 4;
  $self->{ipc} //= 0;
  $self->{non_blocking} //= 1;
  $self->{timeout} //= 0;
}

sub max_procs {
  my ($self, $n) = @_;
  $n // return $self->{max_procs};
  $self->{max_procs} = $n;
}

sub non_blocking {
  my ($self, $n) = @_;
  $n // return $self->{non_blocking};
  $self->{non_blocking} = $n;
}

sub ipc {
  my ($self, $n) = @_;
  $n // return $self->{ipc};
  $self->{ipc} = $n;
}

sub timeout {
  my ($self, $n) = @_;
  $n // return $self->{timeout};
  $self->{timeout} = $n;
}

sub fmap {
  my ($self, $code) = (shift, shift);
  my %pids = ();
  my @rs = ();  # result set of child return values
  my $max = $self->max_procs;
  my $ipc = $self->ipc;
  my $timeout = $self->timeout;
  my $non_blocking = $self->non_blocking;
  for my $proc (@_) {
    my $pipe = $ipc ? IO::Pipe->new : {};
    # max procs?
    while ($max == keys %pids) {
      # free a spot in queue when a process completes
      for my $pid (keys %pids) {
        if (my $kid = waitpid($pid, WNOHANG)) {
          delete $pids{$kid};
          last;
        }
      }
    }
    my $fn = sub {
      my $rs = shift;
      if ($ipc) {
        $pipe->writer();
        $pipe->autoflush;
        print $pipe $rs if defined $rs;
      }
      return 1;
    };
    run_fork {  # processes fork here
      parent {
        my $kid = shift;
        $pids{$kid}++;
        if ($ipc) {
          $pipe->reader();
          if ($non_blocking) {
            $pipe->blocking(0);
          } else {
            $pipe->blocking(1);
          }
          while(<$pipe>) {
            push @rs, $_;
          }
        }
      }
      child {
        if (!$timeout) {
          my $rs = $code->($proc);
          $fn->($rs);
          exit;
        }
        eval {
          local $SIG{ALRM} = sub {
            die "alarm\n"
          };
          alarm $timeout;
          my $rs = $code->($proc);
          $fn->($rs);
          alarm 0;
        };
        if ($@) {
          if ($@ eq "alarm\n") {
            print STDERR "error: timeout $$\n";
          }
          die unless $@ eq "alarm\n";
        }
        exit;
      }
      error {
        die "error: couldn't fork";
      }
    };
  }
  1 while (wait() != -1);  # wait for the stragglers to finish
  return @rs;
}

sub forkmap (&@) {
  my ($code, @args) = @_;
  my %pids = ();
  my $max = $MAX_PROCS;
  for my $proc (@args) {
    while ($max == keys %pids) {
      for my $pid (keys %pids) {
        if (my $kid = waitpid($pid, WNOHANG)) {
          delete $pids{$kid};
          last;
        }
      }
    }
    run_fork {
      parent {
        my $kid = shift;
        $pids{$kid}++;
      }
      child {
        if (!$TIMEOUT) {
          local $_ = $proc;
          $code->();
          exit;
        }
        eval {
          local $SIG{ALRM} = sub {
            die "alarm\n"
          };
          alarm $TIMEOUT;
          local $_ = $proc;
          $code->();
          alarm 0;
        };
        if ($@) {
          if ($@ eq "alarm\n") {
            print STDERR "error: timeout $$\n";
          }
          die unless $@ eq "alarm\n";
        }
        exit;
      }
      error {
        die "error: couldn't fork";
      }
    };
  }
  1 while (wait() != -1);
  return 1;
}

1;

__END__
=head1 NAME

Proc::Forkmap - map with forking

=head1 SYNOPSIS

EXAMPLE:

  use Proc::Forkmap qw(forkmap);

  $Proc::Forkmap::MAX_PROCS = 4;

  sub foo {
    my $n = shift;
    sleep($n);
    print "slept for $n seconds\n";
  }

  my @x = (1, 2, 3);

  forkmap { foo($_) } @x;

  # Object interface

  use Proc::Forkmap;

  sub foo {
    my $x = shift;
    my $t = sprintf("%1.0f", $x + 1);
    sleep $t;
    print "slept $t seconds\n";
  }

  my @x = (rand(), rand(), rand());
  my $p = Proc::Forkmap->new;
  $p->fmap(\&foo, @x);

=head1 DESCRIPTION

This module provides mapping with built-in forking.

=head1 FUNCTIONS

=head2 forkmap

  forkmap { foo($_) } @x;

=head1 VARIABLES

These C<our> variables control only the functional interface.

=head2 MAX_PROCS

Max parallelism.

  $Proc::Forkmap::MAX_PROCS = 4;

=head2 TIMEOUT

Max time in seconds any single child process can run.

  $Proc::Forkmap::TIMEOUT = 2;

=head1 METHODS

=head2 new

  my $p = Proc::Forkmap->new(max_procs => 4);

=over 4

=item B<max_procs>

Maximum number of procs allowed in the pool. The default is 4.

=item B<ipc>

Set IPC on/off state. IPC is off by default.

=item B<non_blocking>

Defaults to 1, and falsy to block.

=back

=head2 max_procs

  $p->max_procs(4);

max_procs setter/getter.

=head2 fmap

  $p->fmap(\&foo, @x);

This method takes a coderef and an array. If IPC is blocking, then it will return a result set. Otherwise, it will continue, waiting for child processes to complete their tasks.

=head2 ipc

  $p->ipc(1);

Turn on/off inter-process communication.

=head2 non_blocking

  $p->non_blocking(1);

If IPC is on, then set IO::Handle blocking state. This might be useful for conditional parallelism.

=head2 timeout

Timeout in seconds.

  $p->timeout(2);

=head1 SEE ALSO

L<Proc::Fork>, L<IO::Pipe>

=head1 AUTHOR

Andrew Shapiro, C<< <trski@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-forkmap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-Forkmap>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Andrew Shapiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
