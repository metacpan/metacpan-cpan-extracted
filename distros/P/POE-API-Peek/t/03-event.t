
# Tests for event related code. See code block labeled "Event fun"

use warnings;
use strict;
use POE;
use Data::Dumper;
use Test::More tests => 20;

use_ok('POE::API::Peek');

my $api = POE::API::Peek->new();

POE::Session->create(
    inline_states => {
        _start => \&_start,
        _stop => \&_stop,
        dummy => sub {},

    },
    heap => { api => $api },
);

POE::Kernel->run();

###############################################

sub _start {
    my $sess = $_[SESSION];
    my $api = $_[HEAP]->{api};

# event_count_to {{{
    my $to_count;
    eval { $to_count = $api->event_count_to() };
    ok(!$@, "event_count_to() causes no exceptions");
    is($to_count, 0, 'event_count_to() returns proper count');
	POE::Session->create(
		inline_states => {
			_start => sub {
                my $new_to_count;
                eval { $new_to_count = $api->event_count_to($sess) };
                ok(!$@, "event_count_to(session) causes no exceptions");
                is($new_to_count, $to_count, 'event_count_to(session) returns proper count');
                eval { $new_to_count = $api->event_count_to($sess->ID) };
                ok(!$@, "event_count_to(ID) causes no exceptions");
                is($new_to_count, $to_count, 'event_count_to(ID) returns proper count');
            },
            _stop => sub {}
        }
    );

# }}}

# event_count_from {{{
    my $from_count;
    eval { $from_count = $api->event_count_from() };
    ok(!$@, "event_count_from() causes no exceptions");
    is($from_count, 0, 'event_count_from() returns proper count');
	POE::Session->create(
		inline_states => {
			_start => sub {
                my $new_from_count;
                eval { $new_from_count = $api->event_count_from($sess) };
                ok(!$@, "event_count_from(session) causes no exceptions");
                is($new_from_count, $from_count, 'event_count_from(session) returns proper count');
                eval { $new_from_count = $api->event_count_from($sess->ID) };
                ok(!$@, "event_count_from(ID) causes no exceptions");
                is($new_from_count, $from_count, 'event_count_from(ID) returns proper count');
            },
            _stop => sub {}
        }
    );
# }}}

# event_queue {{{
    my $queue;
    eval { $queue = $api->event_queue() };
    ok(!$@, "event_queue() causes no exceptions");

    # work around a bug in pre 0.04 releases of POE::XS::Queue::Array.
    if( ($queue->isa('POE::Queue')) or ($queue->isa('POE::XS::Queue::Array')) ) {
        pass('event_queue() returns POE::Queue object');
    } else {
        fail('event_queue() returns POE::Queue object');
    }

# }}}

# event_queue_dump {{{
	my $ver = $POE::VERSION;
	$ver =~ s/_.+$//;
    if($ver >= '0.31') {
        $_[KERNEL]->yield('dummy');

        my @queue;
        eval { @queue = $api->event_queue_dump() };
        ok(!$@, "event_queue_dump() causes no exceptions: $@");
        # 3 = GC the temp sessions (2) + our dummy
        is(scalar @queue, 3, "event_queue_dump() returns the right number of items");

        my $item = $queue[-1];
        is($item->{type}, 'User', 'event_queue_dump() item has proper type');
        is($item->{event}, 'dummy', 'event_queue_dump() item has proper event name');
        is($item->{source}, $item->{destination}, 'event_queue_dump() item has proper source and destination');
    } else {
        my @queue;
        eval { @queue = $api->event_queue_dump() };
        ok(!$@, "event_queue_dump() causes no exceptions: $@");
        is(scalar @queue, 1, "event_queue_dump() returns the right number of items");

        my $item = $queue[0];
        is($item->{type}, '_sigchld_poll', 'event_queue_dump() item has proper type');
        is($item->{event}, '_sigchld_poll', 'event_queue_dump() item has proper event name');
        is($item->{source}, $item->{destination}, 'event_queue_dump() item has proper source and destination');
    }
# }}}

}


sub _stop {


}
