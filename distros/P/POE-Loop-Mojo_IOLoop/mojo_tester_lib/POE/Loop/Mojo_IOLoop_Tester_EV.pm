=for poe_tests
BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::Mojo_IOLoop' }
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::EV' }
use Mojo::IOLoop;
sub skip_tests {
	return "tests for author testing only"
		unless $ENV{AUTHOR_TESTING} or $ENV{AUTOMATED_TESTING};
	return "EV module required to test Mojo::Reactor::EV backend: $@"
		unless eval { require EV; EV->VERSION('4.0'); 1 };
	$ENV{POE_LOOP_USES_POLL} = 1 if EV::backend() == EV::BACKEND_POLL();
	if ($_[0] eq '00_info') {
		my $reactor = Mojo::IOLoop->singleton->reactor;
		diag("Using reactor $reactor");
	}
	return undef;
}
