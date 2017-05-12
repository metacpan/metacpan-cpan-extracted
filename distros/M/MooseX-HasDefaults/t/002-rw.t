#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

do {
    package Person;
    use Moose;
    use MooseX::HasDefaults::RW;

    has name => (
        isa => 'Str',
    );

    has birth_year => (
        is  => 'ro',
        isa => 'Int',
    );

    has favorite_language => (
        isa     => 'Str',
        default => 'Perl',
    );
};

can_ok(Person => qw(name birth_year favorite_language));

my $whacko = Person->new(name => 'Stevan', birth_year => 1924);
is($whacko->name, 'Stevan');
is($whacko->birth_year, 1924);
is($whacko->favorite_language, 'Perl');

$whacko->name('Stevan Little');
$whacko->favorite_language('C#'); # he's dead to us now..

throws_ok {
    $whacko->birth_year(1922);
} qr/read-only accessor/;

is($whacko->name,              'Stevan Little');
is($whacko->favorite_language, 'C#');

