#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

do {
    package Person;
    use Moose;
    use MooseX::HasDefaults::RO;

    has name => (
        isa => 'Str',
    );

    has birth_year => (
        isa => 'Int',
    );

    has favorite_language => (
        is      => 'rw',
        isa     => 'Str',
        default => 'Perl',
    );
};

can_ok(Person => qw(name birth_year favorite_language));

my $whacko = Person->new(name => 'Stevan', birth_year => 1924);
is($whacko->name, 'Stevan');
is($whacko->birth_year, 1924);
is($whacko->favorite_language, 'Perl');

throws_ok {
    $whacko->name('Stevan Little');
} qr/read-only accessor/;

throws_ok {
    $whacko->birth_year(1922);
} qr/read-only accessor/;

$whacko->favorite_language('C#'); # he's dead to us now..
is($whacko->favorite_language, 'C#');

