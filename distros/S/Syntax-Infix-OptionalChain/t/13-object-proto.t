#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?-> operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
    eval { require Object::Proto; 1 }
        or plan skip_all => "Object::Proto not installed";
}

use Syntax::Infix::OptionalChain;

# Object::Proto objects are blessed ARRAY refs with compiled accessors, so
# `?->` calls the accessor (blessed + can); a name with no accessor would fall
# through to array-slot access. We exercise the accessor path here.
Object::Proto::define('My::OP::Addr',   qw(city));
Object::Proto::define('My::OP::Person', qw(name address tags info));

my $p = My::OP::Person->new(
    name    => 'Ada',
    address => My::OP::Addr->new(city => 'London'),
    tags    => [ 'x', 'y' ],
    info    => { role => 'eng' },
);

is($p ?-> name, 'Ada', 'Object::Proto: bareword is an accessor call');
is($p ?-> address ?-> city, 'London', 'Object::Proto: chain object -> object');
is($p ?-> info ?-> role, 'eng', 'Object::Proto: object -> hashref -> key');
is($p ?-> tags ?-> 1,     'y',   'Object::Proto: object -> arrayref -> index');

my $bob = My::OP::Person->new(name => 'Bob');   # no address
is($bob ?-> address ?-> city, undef, 'Object::Proto: undef accessor short-circuits');
is($bob ?-> address ?-> city // 'n/a', 'n/a', 'Object::Proto: // supplies a default');
is($p   ?-> address ?-> city // 'n/a', 'London', 'Object::Proto: default unused when present');

done_testing;
