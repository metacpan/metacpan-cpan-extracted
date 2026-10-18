use strict;
use warnings;

use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl was not built with ithreads'
        unless $Config{useithreads};
}
use threads;

use Net::IP::LPM;

# The object is a handle onto a process-wide C instance table. A thread clone
# must not become a second owner of the parent's table: the parent's entries
# have to survive the child's ordinary teardown, and a later new() must not
# hand the parent's handle to a different object.

my $lpm = Net::IP::LPM->new();
is($lpm->add('10.0.0.0/8', 'PARENT'), 1, "add('10.0.0.0/8')");
is($lpm->lookup('10.1.2.3'), 'PARENT', 'lookup matches before any thread');

threads->create(sub { 1 })->join;

my $after = eval { $lpm->lookup('10.1.2.3') };
is($@, '', 'lookup does not die after an idle thread exited');
is($after, 'PARENT', 'the parent table survives the child thread teardown');

my $other = Net::IP::LPM->new();
is($other->add('192.0.2.0/24', 'OTHER'), 1, "add('192.0.2.0/24') on a second object");
is($lpm->lookup('192.0.2.7'), undef,    'the parent does not see the second object\'s entries');
is($lpm->lookup('10.1.2.3'),  'PARENT', 'the parent still sees its own entries');
is($other->lookup('10.1.2.3'), undef,   'the second object does not see the parent\'s entries');

# The clone policy must not break single-thread use.
my $t = threads->create(sub {
    my $own = Net::IP::LPM->new();
    $own->add('203.0.113.0/24', 'CHILD');
    return $own->lookup('203.0.113.9');
});
is($t->join, 'CHILD', 'a thread can build and use its own table');
is($lpm->lookup('10.1.2.3'), 'PARENT', 'the parent table survives a working child thread too');

done_testing;
