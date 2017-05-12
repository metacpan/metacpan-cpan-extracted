use Test::More tests => 8;
use lib qw(lib);

{

    package Manager;
    use Moose;
	use POE::Filter::Reference;
	use DateTime;
	use Scalar::Util qw/blessed/;
    with qw(MooseX::Workers);

	my @results;
	
	sub stdout_filter { POE::Filter::Reference->new; }
	
    sub worker_manager_start {
        ::is( scalar @results, 0, 'Started with an empty @results array' );
    }

    sub worker_manager_stop {
		::is( scalar @results, 1, 'At end of run, there is 1 result in @results' );

		my ($d, $pid, $curr_pid) = ($results[0]->{date}, $results[0]->{pid}, $$);
		
		::is( blessed($d), 'DateTime', "We got a DateTime object back");
		::is( blessed($d) && $d->ymd . ' ' . $d->hms, '2010-11-15 10:11:12', 'Got the correct DateTime val');		
		::ok( $pid, 'Got a non-zero PID from child' );
		::isnt( $pid, $$, 'PID where the DateTime was created is not the same as current PID');
    }

    sub worker_stdout {
        my ( $self, $output ) = @_;
		push @results, $output;
    }

    sub worker_stderr {
        my ( $self, $output ) = @_;
		::fail("Got STDERR content: $output");
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
		$_[0]->enqueue(
			sub {
				my $d = DateTime->new(   year => 2010,
										 month => 11,
										 day => 15,
										 hour => 10,
										 minute => 11,
										 second => 12,
					);
				print STDOUT @{POE::Filter::Reference->new->put([ {date => $d, pid => $$} ])};
			}
		);
        POE::Kernel->run();
    }
    no Moose;
}

Manager->new()->run();

