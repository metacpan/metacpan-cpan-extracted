
use Test::More tests => 7;

use POE;
use POE::API::Hooks;

my (
	$before_dispatch,
	$after_dispatch,
	$before_create,
	$after_create,
	$before_event_enqueue,
	$after_event_enqueue,
);

eval {
	POE::API::Hooks->add(
		before_event_dispatch => sub {
			$before_dispatch++;
		},
		after_event_dispatch => sub {
			$after_dispatch++;
		},
		before_session_create => sub {
			$before_create++;
		},
		after_session_create => sub {
			$after_create++;
		},
		before_event_enqueue => sub {
			$before_event_enqueue++;
		},
		after_event_enqueue => sub {
			$after_event_enqueue++;
		},
	);
};

is($@,'',"add() exception check");

POE::Session->create(
	inline_states => {
		_start => sub {},
		_stop => sub {},
	}
);

POE::Kernel->run();

is($before_create,1,"before_session_create firing check");
is($after_create,1,"after_session_create firing check");

# did have an exact count in here. but different versions of poe
# have differing number of intermediate events getting fired
# behind your back. so we really just need to see if the callbacks
# got fired at all.
ok($before_dispatch,"before_event_dispatch firing check");
ok($after_dispatch,"after_event_dispatch firing check");

if($POE::VERSION >= 0.31) {
	if($POE::VERSION >= 1.0) {
		is($before_event_enqueue, 3, "before_event_enqueue firing check");
		is($after_event_enqueue, 3, "after_event_enqueue firing check");
	} else {
		is($before_event_enqueue, 1, "before_event_enqueue firing check");
		is($after_event_enqueue, 1, "after_event_enqueue firing check");
	}
} else {
	is($before_event_enqueue, 3, "before_event_enqueue firing check");
	is($after_event_enqueue, 3, "after_event_enqueue firing check");
}
