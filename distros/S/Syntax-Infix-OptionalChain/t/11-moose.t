#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?-> operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
    eval { require Moose; 1 }
        or plan skip_all => "Moose not installed";
}

use Syntax::Infix::OptionalChain;

{
    package My::Moose::Addr;
    use Moose;
    has city => (is => 'ro');
    __PACKAGE__->meta->make_immutable;
}
{
    package My::Moose::Person;
    use Moose;
    has name    => (is => 'ro');
    has address => (is => 'ro');
    has tags    => (is => 'ro', default => sub { [] });
    has info    => (is => 'ro', default => sub { {} });
    __PACKAGE__->meta->make_immutable;
}

my $p = My::Moose::Person->new(
    name    => 'Ada',
    address => My::Moose::Addr->new(city => 'London'),
    tags    => [ 'x', 'y' ],
    info    => { role => 'eng' },
);

is($p ?-> name, 'Ada', 'Moose: bareword is an accessor call');
is($p ?-> address ?-> city, 'London', 'Moose: chain object -> object');
is($p ?-> info ?-> role, 'eng', 'Moose: object -> hashref -> key');
is($p ?-> tags ?-> 1,     'y',   'Moose: object -> arrayref -> index');

my $bob = My::Moose::Person->new(name => 'Bob');
is($bob ?-> address ?-> city, undef, 'Moose: undef accessor short-circuits');
is($bob ?-> address ?-> city // 'n/a', 'n/a', 'Moose: // supplies a default');
is($p   ?-> address ?-> city // 'n/a', 'London', 'Moose: default unused when present');

done_testing;
