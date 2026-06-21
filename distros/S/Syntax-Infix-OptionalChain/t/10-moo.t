#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?-> operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
    eval { require Moo; 1 }
        or plan skip_all => "Moo not installed";
}

use Syntax::Infix::OptionalChain;

{
    package My::Moo::Addr;
    use Moo;
    has city => (is => 'ro');
}
{
    package My::Moo::Person;
    use Moo;
    has name    => (is => 'ro');
    has address => (is => 'ro');                      # a My::Moo::Addr or undef
    has tags    => (is => 'ro', default => sub { [] });
    has info    => (is => 'ro', default => sub { {} });
}

my $p = My::Moo::Person->new(
    name    => 'Ada',
    address => My::Moo::Addr->new(city => 'London'),
    tags    => [ 'x', 'y' ],
    info    => { role => 'eng' },
);

# blessed object -> method (accessor) call
is($p ?-> name, 'Ada', 'Moo: bareword is an accessor call');

# object -> object: chain through an accessor returning another Moo object
is($p?->address?->city, 'London', 'Moo: chain object -> object');

# object -> hashref / arrayref: accessor returns a plain ref, then structural
is($p?->info?->role, 'eng', 'Moo: object -> hashref -> key');
is($p?->tags?->1,     'y',   'Moo: object -> arrayref -> index');

# short-circuit when an accessor yields undef
my $bob = My::Moo::Person->new(name => 'Bob');   # no address
is($bob ?-> address ?-> city, undef, 'Moo: undef accessor short-circuits');
is($bob ?-> address ?-> city // 'n/a', 'n/a', 'Moo: // supplies a default');
is($p   ?-> address ?-> city // 'n/a', 'London', 'Moo: default unused when present');

done_testing;
