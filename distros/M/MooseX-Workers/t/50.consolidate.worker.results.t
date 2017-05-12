use Test::More tests => 52;
use lib qw(lib);

{

    package Manager;
    use Moose;
	use POE::Filter::Reference;
    with qw(MooseX::Workers);

	my @results;
	
	sub stdout_filter { POE::Filter::Reference->new; }
	
    sub worker_manager_start {
        ::is( scalar @results, 0, 'Started with an empty @results array' );
    }

    sub worker_manager_stop {
		@results = sort { $a->{id} <=> $b->{id} } @results;
		::is( scalar @results, 10, 'At end of run, there are 10 results in @results' );
		for ( 0..9 ) {
			my $expected = $_ * 2;
			::is( $results[$_]->{id}, $_, "After sorting, ${_}th entry has id #$_" );
			::is( $results[$_]->{result}, $expected, "After sorting, ${_}th entry has result '$expected'" );
		}
    }

    sub worker_stdout {
        my ( $self, $output ) = @_;
		push @results, $output;
    }

    sub worker_stderr {
        my ( $self, $output ) = @_;
        ::is( $output, 'WORLD' );
    }
    sub worker_error {
		::fail('Got error?'.@_)
	}
    sub worker_finished  {
		::pass('worker finished')
	}

    sub worker_started {
		::pass('worker started')
	}
    
    sub run { 
        for my $num (0..9) {
            $_[0]->enqueue( sub {
                print STDOUT @{POE::Filter::Reference->new->put([ {id => $num, result => $num*2} ])};
                print STDERR "WORLD\n";
            } );
        }
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();

