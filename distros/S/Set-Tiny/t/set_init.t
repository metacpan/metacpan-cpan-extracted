use warnings;
use strict;
use Test::More tests => 6;

# test to make sure that the short initializer (`set()`) works

use Set::Tiny qw(set);

my $a = set();
my $b = set(qw( a b c ));

isa_ok $a, 'Set::Tiny';
isa_ok $b, 'Set::Tiny';

is $a->as_string, '()',      "empty set stringification";
is $b->as_string, '(a b c)', "non-empty set stringification";

my $c = set( [ 'a', 'b', 'c' ] );
is $c->as_string, '(a b c)', "initializer can be called with arrayref";

my $d = set($c);
is $d->as_string, '(a b c)', "initializer can be called on existing set";
