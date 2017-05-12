use strict;
use warnings;

use Test::More 'tests' => 4;

package foo; {
    use Object::InsideOut;
    my @foo :Field :Acc(foo) :Default({});
}

package bar; {
    use Object::InsideOut;
    my @bar :Field :Acc(bar) :Arg(foo) :Default({});
}

package main;

my $foo1 = foo->new();
my $foo2 = foo->new();

$foo1->foo()->{a} = 1;
$foo2->foo()->{a} = 2;

is($foo1->foo()->{a}, 1);
is($foo2->foo()->{a}, 2);

my $bar1 = bar->new();
my $bar2 = bar->new();

$bar1->bar()->{a} = 1;
$bar2->bar()->{a} = 2;

is($bar1->bar()->{a}, 1);
is($bar2->bar()->{a}, 2);

exit(0);

# EOF
