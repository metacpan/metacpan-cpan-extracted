use Test::More tests => 7;
use lib qw(lib);

{

    package Manager;
    use Moose;
	use POE::Filter::Reference;
    with qw(MooseX::Workers);

	sub stderr_filter { ::pass("stderr_filter was called"); POE::Filter::Reference->new; }
	
    sub worker_manager_start {
        ::pass('started worker manager');
    }

    sub worker_manager_stop {
        ::pass('stopped worker manager');
    }

    sub worker_stdout {
        my ( $self, $output ) = @_;
        ::is( $output, 'HELLO' );
    }

    sub worker_stderr {
        my ( $self, $output ) = @_;
        ::is( $output->{msg}, 'WORLD' );
    }
    sub worker_error { ::fail('Got error?'.@_) }
    sub worker_finished  { ::pass('worker finished') }

    sub worker_started { ::pass('worker started') }
    
    sub run { 
        $_[0]->spawn(
			sub {
				print STDOUT "HELLO";
				print STDERR @{ POE::Filter::Reference->new->put([ {msg => "WORLD"} ]) };
			}
		);
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();
