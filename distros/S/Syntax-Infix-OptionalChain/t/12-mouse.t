#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?-> operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
    eval { require Mouse; 1 }
        or plan skip_all => "Mouse not installed";
}

use Syntax::Infix::OptionalChain;

{
    package My::Mouse::Addr;
    use Mouse;
    has city => (is => 'ro');
    __PACKAGE__->meta->make_immutable;
}
{
    package My::Mouse::Person;
    use Mouse;
    has name    => (is => 'ro');
    has address => (is => 'ro');
    has tags    => (is => 'ro', default => sub { [] });
    has info    => (is => 'ro', default => sub { {} });
    __PACKAGE__->meta->make_immutable;
}

my $p = My::Mouse::Person->new(
    name    => 'Ada',
    address => My::Mouse::Addr->new(city => 'London'),
    tags    => [ 'x', 'y' ],
    info    => { role => 'eng' },
);

is($p ?-> name, 'Ada', 'Mouse: bareword is an accessor call');
is($p ?-> address ?-> city, 'London', 'Mouse: chain object -> object');
is($p ?-> info ?-> role, 'eng', 'Mouse: object -> hashref -> key');
is($p ?-> tags ?-> 1,     'y',   'Mouse: object -> arrayref -> index');

my $bob = My::Mouse::Person->new(name => 'Bob');
is($bob ?-> address ?-> city, undef, 'Mouse: undef accessor short-circuits');
is($bob ?-> address ?-> city // 'n/a', 'n/a', 'Mouse: // supplies a default');
is($p   ?-> address ?-> city // 'n/a', 'London', 'Mouse: default unused when present');

done_testing;
