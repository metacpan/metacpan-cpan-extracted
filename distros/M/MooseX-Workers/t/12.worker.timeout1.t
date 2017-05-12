use Test::More tests => 6;
use lib qw(lib);
use strict;

# This timeout demonstration covers the case where the timeout is invoked before the
# child exits on its own. 

{
    package Manager;
    use MooseX::Workers::Job;
    use Moose;
    with qw(MooseX::Workers);

    sub worker_manager_start {
        ::pass('started worker manager');
    }

    sub worker_manager_stop {
        ::pass('stopped worker manager');
    }

    sub worker_stdout {
        my ( $self, $output, $wheel ) = @_;
        ::is( $output, "HELLO", "STDOUT" );
    }

    sub worker_stderr {
        my ( $self, $output, $wheel ) = @_;
        ::fail("STDERR should never happen. We should have timed out and not gotten here.");
    }

    sub worker_error { ::fail('Got error?'.@_) }

    sub worker_timeout  { 
        my ( $self, $job ) = @_;
        ::pass("worker timeout");
    }

    sub worker_finished  { 
        my ( $self, $job ) = @_;
        ::pass("worker_finished");
    }

    sub worker_started { 
        my ( $self, $job ) = @_;
        ::pass("worker started");
    }
    
    sub run { 
        my $job = MooseX::Workers::Job->new(
            timeout => 1,
            command => sub { print "HELLO\n"; sleep 2; print STDERR "WORLD\n"; },
        );
        $_[0]->run_command( $job );
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();


