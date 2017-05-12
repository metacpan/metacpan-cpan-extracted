#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

do {
    package Person;
    use Moose;
    use MooseX::HasDefaults::RO;

    has name => (
        isa => 'Str',
    );

    has blah => (
        is        => undef,
        predicate => 'has_blah',
    );
};

can_ok(Person => qw(name));
ok(!Person->can('blah'));

my $person = Person->new(name => 'Joe', blah => 'secret');
is($person->name, 'Joe');
is($person->{blah}, 'secret', 'an attribute was created even though it has no accessor');
ok($person->has_blah);

