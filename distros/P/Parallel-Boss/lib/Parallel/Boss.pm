package Parallel::Boss;
use 5.012;
use strict;
use warnings;
our $VERSION = "0.03";
my $XS_VERSION=$VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load("Parallel::Boss", $XS_VERSION);

=head1 NAME

Parallel::Boss - manage worker processes

=head1 VERSION

This document describes Parallel::Boss version 0.03

=head1 SYNOPSIS

    use Parallel::Boss;

    my $worker = sub {
        my ( @args ) = @_;
        # pretend to be working
        ...;
    };

    Parallel::Boss->run(
        num_workers  => 4,
        args         => \@args,
        exit_timeout => 15,
        worker       => $worker,
    );

=head1 DESCRIPTION

Module running specified number of worker processes.

=head1 METHODS

=cut

=head2 run

     $class->run(%params)

start specified number of workers and supervise them. If any of the workers
exits, a new one will be started as a replacement. If parent process receives
HUP signal, then it sends HUP signal to every worker process and restarts
workers if they exit. If parent process receives INT, QUIT, or TERM, it sends
TERM to all workers, waits for up to I<exit_timeout> seconds till they all
exit, and sends KILL to those workers that are still running, after all workers
exited the run method returns. Each worker process runs watchdog thread that
detects if the parent process has died and terminates the worker by sending it
first SIGTERM and then calling _exit(2) after I<exit_timeout> seconds if the
worker is still running.

The following parameters are accepted:

=over 4

=item B<num_workers>

number of workers to start

=item B<args>

reference to array of arguments that should be passed to worker subroutine

=item B<exit_timeout>

when parent process signalled to exit it first sends to all workers SIGTERM. If
exit_timeout is set and greater than zero then after exit_timeout workers that
are still running are sent SIGKILL.

=item B<worker>

subroutine that will be executed by every worker. If it returns, the worker
process exits. The I<args> array is passed to subroutine as the list of
arguments.

=back

=cut

sub run {
    my ( $class, %args ) = @_;

    my $self = bless \%args, $class;

    pipe( my $rd, my $wr ) or die "Couldn't create a pipe";
    $self->{_rd} = $rd;
    $self->{_wr} = $wr;

    local $SIG{QUIT} = local $SIG{INT} = local $SIG{TERM} = sub {
        $self->{_finish} = 1;
        $self->{_wr}->close;
        $self->_kill_children("TERM");
        alarm $self->{exit_timeout} if $self->{exit_timeout};
    };
    local $SIG{HUP} = sub { $self->_kill_children("HUP"); };
    local $SIG{ALRM} = sub {
        $self->_kill_children("KILL") if $self->{_finish};
    };

    for ( 1 .. $self->{num_workers} ) {
        $self->_spawn;
    }

    while (1) {
        my $pid = wait;
        delete $self->{_workers}{$pid} or next;
        if ($self->{_finish}) {
            last unless keys %{ $self->{_workers} };
        } else {
            $self->_spawn;
        }
    }
}

sub _spawn {
    my ($self) = @_;
    my $pid = fork;
    if ( not defined $pid ) {
        $self->_kill_children("KILL");
        die "Couldn't fork, exiting: $!";
    }

    if ($pid) {
        $self->{_workers}{$pid} = 1;
    }
    else {
        eval {
            $self->{_wr}->close;
            $SIG{$_} = 'DEFAULT' for qw(QUIT HUP INT TERM ALRM);
            _start_watchdog( $self->{_rd}->fileno, ($self->{exit_timeout} // 0 ));
            $self->{worker}->( $self, @{ $self->{args} } );
        };
        exit 0;
    }
}

sub _kill_children {
    my ($self, $sig) = @_;

    kill $sig => keys %{ $self->{_workers} };
}

1;

__END__

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
