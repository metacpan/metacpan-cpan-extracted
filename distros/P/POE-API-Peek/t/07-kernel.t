
use Test::More tests => 11;

use warnings;
use strict;
use POE;
use Data::Dumper;

use_ok('POE::API::Peek');

my $api = POE::API::Peek->new();

my $sess = POE::Session->create(
    inline_states => {
        _start => \&_start,
        _stop => sub {},

    },
    heap => { api => $api },
);

POE::Kernel->run();

###############################################

sub _start {
    my $sess = $_[SESSION];
    my $api = $_[HEAP]->{api};
    my $cur_sess;

    ok($api->is_kernel_running, "is_kernel_running() successfully reports that Kernel is in fact running.");
    is($api->active_event,'_start', "active_event() returns proper event name");

# kernel_memory_size {{{
	my $size;
	eval { $size = $api->kernel_memory_size() };
	is($@, '', "kernel_memory_size() causes no exceptions");

	# we can't really test this value much since its going to be different on
	# every system, and even between runs

	ok(defined $size, "kernel_memory_size() returns data");
	ok($size > 0, "kernel_memory_size() returns non-zero value");

# }}}


# event_list {{{
	my $events;
	eval { $events = $api->event_list() };
	is($@, '', "event_list() causes no exceptions");

	is(ref $events, 'HASH', "event_list() returns hashref");
	ok(keys %$events, "event_list() returns populated hashref");

	my $id = $sess->ID;

	is_deeply($events, { $id => [ '_start', '_stop' ] }, "event_list() returns correct list of sessions and events");

# }}}

    is($api->which_loop(), 'POE::Loop::Select', 'which_loop() loop name check');

}


