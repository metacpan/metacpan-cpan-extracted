package Proc::Forkmap;
use POSIX qw(:sys_wait_h);
use Proc::Fork;
use Carp;
use strict;
use warnings;
use 5.010;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(forkmap);

our $VERSION = '0.2201';
our $MAX_PROCS = 4;
our $TIMEOUT = 0;
our $IPC = 1;

sub forkmap (&@) {
  my ($code, @args) = @_;
  my %pids = ();
  my $max = $MAX_PROCS;

  my ($reader, $writer);
  if ($IPC) {
    pipe($reader, $writer) or die "pipe failed: $!";
    select((select($writer), $| = 1)[0]);  # autoflush
  }

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
        close $reader if $IPC;
        if (!$TIMEOUT) {
          local $_ = $proc;
          my $res = $code->();
          print $writer "$res\n" if $IPC;
          exit;
        }
        eval {
          local $SIG{ALRM} = sub {
            die "alarm\n"
          };
          alarm $TIMEOUT;
          local $_ = $proc;
          my $res = $code->($proc);
          print $writer "$res\n" if $IPC;
          alarm 0;
        };
        if ($@) {
          if ($@ eq "alarm\n") {
            print STDERR "error: timeout $$\n";
          } else {
            die $@;
          }
        }
        exit;
      }
      error {
        die "error: couldn't fork";
      }
    };
  }

  1 while (wait() != -1);

  close $writer if $IPC;
  my @res;
  if ($IPC) {
    while (<$reader>) {
      chomp;
      push @res, $_;
    }
    close $reader;
  }
  return @res;
}

1;

__END__
=head1 NAME

Proc::Forkmap - map with forking

=head1 SYNOPSIS

EXAMPLE:

  use Proc::Forkmap;

  $Proc::Forkmap::MAX_PROCS = 4;

  sub foo {
    my $n = shift;
    sleep $n;
    print "slept for $n seconds\n";
  }

  my @x = (1, 4, 2);

  forkmap { foo($_) } @x;

=head1 DESCRIPTION

Mapping with built-in forking.

=head1 INTERFACE

=head2 forkmap

  forkmap { foo($_) } @x;

Run code blocks in parallel.

=head2 IPC

IPC is off by default. Set to 1 for results to get returned to the parent.
IPC is handled by creating a pipe, with reader and writer file handles.
Currently, only scalar values are supported for the function return values.
Pipes operate as simple byte streams, so any data sent through
the pipe must be serialized into a scalar (e.g., a string or a number)
before being transmitted.

  $Proc::Forkmap::IPC = 1;  # (default: 0)
  my @results = forkmap { foo($_) } @x;

=head2 MAX_PROCS

Max parallelism.

  $Proc::Forkmap::MAX_PROCS = 4;  # (default: 4)

=head2 TIMEOUT

Max time in seconds any single child process can run.

  $Proc::Forkmap::TIMEOUT = 2;  # (default: 0)

=head1 SEE ALSO

L<Proc::Fork>

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
