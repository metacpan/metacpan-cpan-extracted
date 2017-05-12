use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

{
    package Foo;
    use Moose;
    use MooseX::MultiMethods;
    multi method bar (Int $x, Num $y) {}
    multi method bar (Num $x, Int $y) {}
}

my $foo = Foo->new;
dies_ok(sub {
    $foo->bar(23, 42);
});
