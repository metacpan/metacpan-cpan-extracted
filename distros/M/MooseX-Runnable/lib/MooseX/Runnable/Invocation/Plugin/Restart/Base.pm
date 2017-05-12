package MooseX::Runnable::Invocation::Plugin::Restart::Base;

our $VERSION = '0.10';

use Moose::Role;
use MooseX::Types::Moose qw(Int);
use namespace::autoclean;

has 'child_pid' => (
    is        => 'rw',
    isa       => Int,
    clearer   => 'clear_child_pid',
    predicate => 'has_child_pid',
);

# XXX: blocking is probably a bad idea; refactor this later
requires 'run_parent_loop';

my $is_debug = sub { return 1;
    $_[0]->meta->does_role('MooseX::Runnable::Invocation::Plugin::Debug');
};

sub _restart_parent_setup {
    my $self = shift;
}

sub restart {
    my $self = shift;
    return unless $self->has_child_pid;
    eval { $self->_debug_message("Restarting...") };
    kill 'HUP', $self->child_pid;
}

sub kill_child {
    my $self = shift;
    return unless $self->has_child_pid;
    eval { $self->_debug_message("Killing ", $self->child_pid) };

    kill 'KILL', $self->child_pid;
    $self->clear_child_pid;
}

around 'run' => sub {
    my ($next, $self, @args) = @_;
    my $pid = fork();
    if($pid){
        local $SIG{CHLD} = sub {
            # handle the case where the child dies unexpectedly
            waitpid $self->child_pid, 0;
            $self->clear_child_pid;
            my ($code, $sig) = ($? >> 8, $? & 127);
            eval { $self->_debug_message(
                "Exiting early, child died with status $code (signal $sig).",
            )};

            # relay the error up, so the shell (etc.) can see it
            kill $sig, $$ if $sig; # no-op?
            exit $code;
        };

        # parent
        $self->child_pid( $pid );
        $self->_restart_parent_setup;

        my $code = $self->run_parent_loop;
        eval { $self->_debug_message("Shutting down.") };

        $self->kill_child;
        return $code;
    }
    else {
        # we go to all this effort so that the child process is always
        # free of any "infection" by the parent (like the event loop,
        # used by the parent to receive filesystem events or signals,
        # which can't be cancelled by the child)

        my $child_body; $child_body = sub {
            while(1){
                my $pid2 = fork;
                if($pid2){
                    # parent? wait for kid to die
                    local $SIG{HUP} = sub {
                        kill 'KILL', $pid2;
                    };
                    waitpid $pid2, 0;
                    my $code = $? >> 8;
                    if($code == 0){
                        goto $child_body;
                    }
                    else {
                        eval { $self->_debug_message(
                            "Child exited with non-zero status; aborting.",
                        )};
                        exit $code;
                    }
                }
                else {
                    # child? actually do the work
                    exit $self->$next(@args);
                }
            }
        };

        $child_body->();
    }
};

1;
