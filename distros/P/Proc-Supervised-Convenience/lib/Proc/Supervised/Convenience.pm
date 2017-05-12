package Proc::Supervised::Convenience;
BEGIN {
  $Proc::Supervised::Convenience::VERSION = '1.01';
}

=head1 NAME

Proc::Supervised::Convenience - Supervise concurrent worker processes

=head1 VERSION

version 1.01

=cut

use POE;
use POE::Component::Supervisor;
use POE::Component::Supervisor::Supervised::Proc;
use POSIX;
use Moose;
with 'MooseX::Getopt';

has processes => (
    is          => 'ro',
    isa         => 'Int',
    cmd_aliases => ['j'],
    traits      => ['Getopt']
);
has detach => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
    cmd_aliases => ['d'],
    traits      => ['Getopt']
);
has program => (
    is       => 'ro',
    isa      => 'CodeRef',
    traits   => ['NoGetopt'],
    required => 1
);
has logger => (
    is       => 'ro',
    isa      => 'Log::Dispatch',
    traits   => ['NoGetopt'],
    required => 0
);

sub detach_me {
    my $self = shift;
    $self->logger->info("Detaching $$") if $self->logger;

    local $SIG{HUP} = sub {
        $self->logger->debug("Got sighup in $$.") if $self->logger;
    };
    my $child = fork();
    $child >= 0 or die "Fork failed ($!)";
    $child == 0 or exit 0;

    POSIX::setsid;
# close std file descriptors
    if (-e "/dev/null") {
        # On Unix, we want to point these file descriptors at /dev/null,
        # so that any libary routines that try to read form stdin or
        # write to stdout/err will have no effect (Stevens, APitUE, p. 426
        # and [RT 51066].
        open STDIN, '/dev/null';
        open STDOUT, '>>/dev/null';
        open STDERR, '>>/dev/null';
    } else {
        close(STDIN);
        close(STDOUT);
        close(STDERR);
    }
}

sub make_children {
    my $self = shift;

    map {
        POE::Component::Supervisor::Supervised::Proc->new(
            restart_policy => 'permanent',
            until_kill => 2,
            until_term => 1,
            program => sub {
                local $SIG{HUP} = 'IGNORE'; # so we can killall -HUP
                $self->program->(@{ $self->extra_argv });
            },
        ) } 1 .. $self->processes
}

sub supervise {
    my $self = shift;
    $self->detach_me() if $self->detach;

    my $supervisor;
    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->sig(INT  => 'kill_all');
                $_[KERNEL]->sig(HUP  => 'restart_all');
                $_[KERNEL]->sig(USR1 => 'relaunch');

                $supervisor = POE::Component::Supervisor->new(
                    children => [ $self->make_children() ],
                    restart_policy => 'one',
                    until_kill => 0.2,
                    ($self->logger ? (logger => $self->logger) : ())
                );
            },
            kill_all => sub { $supervisor->logger->info(" *** Stopping all *** ");
                            $supervisor->stop;
                            $_[KERNEL]->sig_handled
                        },
            restart_all => sub { $supervisor->logger->info( " *** Restarting all *** ");
                            $supervisor->stop;
                            $_[KERNEL]->sig_handled;
                            $supervisor->start($self->make_children());
                        },
            relaunch => sub { $supervisor->logger->info( " *** Relaunching *** ");
                            $supervisor->stop;
                            $_[KERNEL]->sig_handled;
                            exec ($0, @{ $self->ARGV });
                        },
        }
    );

    POE::Kernel->run();
}

1;

__END__

=head1 SYNOPSIS

driver script:

  #!/usr/bin/perl

  use Proc::Supervised::Convenience;

  Proc::Supervised::Convenience
    ->new_with_options( program => \&work )
    ->supervise;

  sub work {
    my @args = @_;
    # code to run forever
  }

invocation:

  ./work -d -j 10 foo bar

=head1 FEATURES

=over 4

=item * auto-restarts worker processes

=item * kill -HUP  to restart all workers

=item * kill -INT  to stop

=item * kill -USR1 to relaunch

=back


=head1 Command-line options

=over 4

=item * --detach | -d       # detach from terminal

=item * --processes | -j N  # run N copies of &work

=back

Any remaining command line arguments are passed on as is to your work subroutine.

=head1 SEE ALSO

L<POE::Component::Supervisor>.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
