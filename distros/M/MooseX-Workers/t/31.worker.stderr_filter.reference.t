use Test::More tests => 8;
use lib qw(lib);

{

    package Manager;
    use Moose;
	use POE::Filter::Reference;
    with qw(MooseX::Workers);

	sub stdout_filter { ::pass("stdout_filter was called"); POE::Filter::Reference->new; }
	
    sub worker_manager_start {
        ::pass('started worker manager');
    }

    sub worker_manager_stop {
        ::pass('stopped worker manager');
    }

    sub worker_stdout {
        my ( $self, $output ) = @_;
        ::is( $output->{msg}, 'HELLO' );
    }

    sub worker_stderr {
        my ( $self, $output ) = @_;
        ::is( $output, 'WORLD' );
    }
    sub worker_error { ::fail('Got error?'.@_) }
    sub worker_finished  { ::pass('worker finished') }

    sub worker_started { ::pass('worker started') }
    
    sub run { 
        $_[0]->spawn(
			sub {
				print STDOUT @{ POE::Filter::Reference->new->put([ {msg => "HELLO"} ]) };
				print STDERR "WORLD\n"
			}
		);
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();
