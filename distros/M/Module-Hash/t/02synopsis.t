use strict;
use Test::More tests => 1;
use Module::Hash;

tie my %MOD, "Module::Hash";

my $number = $MOD{"Math::BigInt"}->new(42);

ok( $number->isa("Math::BigInt") );
