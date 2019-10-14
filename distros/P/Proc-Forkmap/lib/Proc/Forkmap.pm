package Proc::Forkmap;
use POSIX qw(:sys_wait_h);
use Proc::Fork;
use Carp;
use IO::Pipe;
use strict;
use warnings;
use 5.010;


our $VERSION = '0.2';


sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->_init;
    return $self;
}


sub _init {
    my $self = shift;
    $self->{max_kids} //= 4;
    $self->{ipc} //= 0;
    $self->{non_blocking} //= 1;
}


sub max_kids {
    my ($self, $n) = @_;
    $n // return $self->{max_kids};
    $self->{max_kids} = $n;
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


sub fmap {
    my ($self, $code) = (shift, shift);
    my %pids = ();
    my @rs = ();  # result set of child return values
    my $max = $self->max_kids;
    my $ipc = $self->ipc;
    my $non_blocking = $self->non_blocking;
    for my $proc (@_) {
        my $pipe = $ipc ? IO::Pipe->new : {};
        # max kids?
        while ($max == keys %pids) {
            # free a spot in queue when a process completes
            for my $pid (keys %pids) {
                if (my $kid = waitpid($pid, WNOHANG)) {
                    delete $pids{$kid};
                    last;
                }
            }
        }

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
                my $rs = $code->($proc);
                if ($ipc) {
                    $pipe->writer();
                    $pipe->autoflush;
                    print $pipe $rs if defined $rs;
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


1;


__END__
=head1 NAME

Proc::Forkmap - map with forking

=head1 SYNOPSIS

EXAMPLE:

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

This module supplies an easy to use map method that provides built-in forking and IPC.

=head1 METHODS

=head2 new

    my $p = Proc::Forkmap->new(max_kids => 4)

=over 4

=item B<max_kids>

Maximum number of kids allowed in the pool. The default is 4.

=item B<ipc>

Set IPC on/off state. IPC is off by default.

=item B<non_blocking>

Defaults to 1, and falsy to block.

=back

=head2 ipc

    $p->ipc(1)

Turn on/off inter-process communication.

=head2 max_kids

    $p->max_kids(4);

max_kids setter/getter.

=head2 non_blocking

    $p->non_blocking(1)

If IPC is on, then set IO::Handle blocking state. This might be useful for conditional parallelism.

=head2 fmap

    $p->fmap(\&foo, @x);

This method takes a coderef and an array. If IPC is blocking, then it will return a result set. Otherwise, it will continue, waiting for child processes to complete their tasks.

=head1 TODO

1. Timeouts

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

Copyright 2019 Andrew Shapiro.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
