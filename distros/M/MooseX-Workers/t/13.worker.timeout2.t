use Test::More tests => 7;
use lib qw(lib);
use strict;

# This timeout demonstration covers the case where the child exits on its own before
# the timeout is reached. If we're not careful here the POE timer will still be active,
# and the program will sit around not exiting when it's supposed to. That's very bad
# if your timeout setting is generous. 

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
        ::is( $output, "WORLD", "STDERR" );
    }

    sub worker_error { ::fail('Got error?'.@_) }

    sub worker_timeout  { 
        my ( $self, $job ) = @_;
        ::fail("worker timeout");
    }

    sub worker_finished  { 
        my ( $self, $job ) = @_;
        ::pass("worker_finished");
    }

    sub worker_started { 
        my ( $self, $job ) = @_;
        ::pass("worker started");
    }
    
    sub sig_child { 
        my ( $self, $job ) = @_;
        ::pass("sig_child");
    }
    
    sub run { 
        my $job = MooseX::Workers::Job->new(
            timeout => 10,
            command => sub { print "HELLO\n"; print STDERR "WORLD\n"; },
        );
        $_[0]->run_command( $job );
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();


