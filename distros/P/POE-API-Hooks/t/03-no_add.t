
use Test::More tests => 2;

use POE;
use POE::API::Hooks;

$SIG{__WARN__} = sub { die shift; };

my $test;
eval {
	POE::Session->create(
		inline_states => {
			_start => sub { $test++ },
			_stop => sub {},
		}
	);

	POE::Kernel->run();
};

is($@,'', "normal execution with no hooks - exception check");
ok($test, "normal execution with no hooks - event firing test");
