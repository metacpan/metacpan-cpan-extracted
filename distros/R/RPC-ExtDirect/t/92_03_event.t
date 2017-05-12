use strict;
use warnings;

use Test::More;
use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 18;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

use RPC::ExtDirect::Event;
use RPC::ExtDirect::NoEvents;

# Test Event with data

my $event = eval { RPC::ExtDirect::Event->new('foo', 'bar') };

is     $@, '', "Event new() eval $@";
ok     $event, "Event object created";
ref_ok $event, 'RPC::ExtDirect::Event';

my $expected_result = {
    type => 'event',
    name => 'foo',
    data => 'bar',
};

my $real_result = eval { $event->result() };

is      $@, '',                         "Event result() eval $@";
ok      $real_result,                   "Event result() not empty";
is_deep $real_result, $expected_result, "Event result() deep";

# Test Event without data

$event = eval { RPC::ExtDirect::Event->new('baz') };

is     $@, '', "Event new() eval $@";
ok     $event, "Event object created";
ref_ok $event, 'RPC::ExtDirect::Event';

$expected_result = {
    type => 'event',
    name => 'baz',
    data => undef,
};

$real_result = eval { $event->result() };

is      $@, '',                         "Event result() eval $@";
ok      $real_result,                   "Event result() not empty";
is_deep $real_result, $expected_result, "Event result() deep";

# Test the stub

my $no_events = eval { RPC::ExtDirect::NoEvents->new() };

is     $@, '',     "NoEvents new() eval $@";
ok     $no_events, "NoEvents new() object created";
ref_ok $no_events, 'RPC::ExtDirect::NoEvents';

$expected_result = {
    type => 'event',
    name => '__NONE__',
    data => '',
};

$real_result = eval { $no_events->result() };

is      $@, '',                         "NoEvents result() eval $@";
ok      $real_result,                   "NoEvents result() not empty";
is_deep $real_result, $expected_result, "NoEvents result() deep";

