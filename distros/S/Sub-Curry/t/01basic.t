use Test::More tests => 26;
BEGIN { require_ok('Sub::Curry') };

#########################

### Test interface

use strict;
use Scalar::Util qw/ reftype blessed /;

BEGIN {
    eval { package Foo1; Sub::Curry::->import(qw/ curry /) };
    ok($@ eq '', 'import');

    eval { package Foo2; Sub::Curry::->import(qw/ :CONST /) };
    ok($@ eq '', 'import');

    eval { package Foo3; Sub::Curry::->import(qw/ BLACKHOLE /) };
    ok($@ eq '', 'import');

    eval { package Foo; Sub::Curry::->import(qw/ :ALL /) };
    ok($@ eq '', 'import');
}

use Sub::Curry ':ALL';

ok(defined &curry, 'curry');
ok(defined &HOLE, 'HOLE');
ok(defined &ANTIHOLE, 'ANTIHOLE');
ok(defined &BLACKHOLE, 'BLACKHOLE');
ok(defined &WHITEHOLE, 'WHITEHOLE');
ok(defined &ANTISPICE, 'ANTISPICE');
ok(defined &Sub::Curry::Hole, 'Hole');

my @methods = qw/
    new
    clone
    call
    spice
    cursed
/;

ok(Sub::Curry::->can($_), "can $_")
    for @methods;

my @spice = ('a', 'b', 'c', HOLE, 'd', ANTISPICE);
my $o = Sub::Curry::->new(sub { 1 }, @spice);

ok($o, 'new');
ok(blessed($o) eq Sub::Curry::, 'is object');
ok(reftype($o) eq 'CODE', 'is code');

my $clone = $o->clone;
ok($clone, 'clone');
ok(eval { $clone->() }, 'run clone');

my $cursed = $o->cursed;
ok($cursed, 'cursed');
ok(!defined blessed($cursed), 'cursed not blessed');
ok(eval { $cursed->() }, "run cursed");

ok(eq_array([ $o->spice ], \@spice), 'spice');
