use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

BEGIN {
    if ($threads::shared::VERSION lt '0.95') {
        print("1..0 # Skip Needs threads::shared 0.95 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 8;

package Foo; {
    use Object::InsideOut ':SHARED';
    my @objs :Field :All(obj);
}

package Bar; {
    use Object::InsideOut;
    my @objs :Field :All(obj);
    my @value :Field :All(value) :Type(numeric);

    sub num :Numerify { $value[${$_[0]}]; }

    use overload (
        '='  => 'clone',
        '++' => sub { $value[${$_[0]}]++; shift },
    );
}

package main;
MAIN:
{
    my $foo = Foo->new();
    my $foo2 = Foo->new('obj'=>$foo);
    my $oof = $foo2->obj();
    isnt($oof, $foo             => 'Shared objects are not the same');
    if (! ok($oof == $foo       => 'However, they equate')) {
        diag("Original object:  ref(\$foo)=" . ref($foo) . '  ID=' . $$foo);
        diag("Shared   object:  ref(\$oof)=" . ref($oof) . '  ID=' . $$oof);
        no strict 'refs';
        diag('Equality: ' . &{'Foo::(=='}($foo, $oof));
    }

    my $bar = Bar->new('value' => 42);
    ok($oof != $bar             => "Different objects don't equate");
    ok($$oof == $$bar           => "Even if they have the same ID");

    my $bar2 = Bar->new('obj'=>$bar);
    my $rab = $bar2->obj();
    is($rab, $bar               => 'Non-shared objects are the same');
    ok($rab == $bar             => 'And they equate');

    ++$rab;
    is($rab->value(), 43        => '++ worked');
    is($bar->value(), 42        => 'Copy constuctor worked');
}

exit(0);

# EOF
