# the only interesting thing here is that we load Glib first, so POE
# uses the right loop.
use strict; use warnings;

use Glib;
#use POE qw(Loop::Glib); # this is another way to specify which loop to use
#use POE::Kernel { loop => 'Glib' }; # and yet another way.
use POE; # let POE auto-detect the loop

POE::Session->create (
	inline_states => {
		_start => sub {
			$_[KERNEL]->yield('foo');
		},
		foo => sub {
			print "bar\n";
		},
		_stop => sub {},
	},
);

$poe_kernel->run;
