use strict;
use warnings;
use utf8;
use Test::More;
use Test::CallCounter;

{
    package Foo;
    sub bar($) { 1 }
}

my $orig = prototype(\&Foo::bar);

my $g = Test::CallCounter->new('Foo', 'bar');

my $replaced = prototype(\&Foo::bar);

is($orig, $replaced);

done_testing;

