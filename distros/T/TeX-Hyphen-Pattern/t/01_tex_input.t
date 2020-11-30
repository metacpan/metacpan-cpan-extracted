#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use open ':std', ':locale';
use Test::More;

our $VERSION = v1.1.1;

eval {
    require TeX::Hyphen;
    1;
} or do {
    plan 'skip_all' => q{TeX::Hyphen required for testing compatibility};
};

if ( $ENV{'AUTHOR_TESTING'} ) {
    eval {
        require Test::NoWarnings;
        1;
    } or do {
        diag q{Not testing for warnings};
    };
}

plan 'tests' => 3 + 1;

use TeX::Hyphen::Pattern;
my $thp   = TeX::Hyphen::Pattern->new();

$thp->label('Nb');
my $hyph   = TeX::Hyphen->new( $thp->filename );
my $words = q{ukeskortene attende betre};
my $broken = join q{ }, map { $hyph->visualize($_) } split / /sm, $words;
is( q{ukes-kort-ene at-ten-de be-tre}, $broken, q{Norwegian Bokmål} );

$thp->label('Nn');
$hyph   = TeX::Hyphen->new( $thp->filename );
$words = q{ukeskortene attende betre};
$broken = join q{ }, map { $hyph->visualize($_) } split / /sm, $words;
is( q{ukes-kort-ene att-en-de bet-re}, $broken, q{Norwegian Nynorsk} );

$thp->label('No');
$hyph   = TeX::Hyphen->new( $thp->filename );
$words = q{ukeskortene attende betre};
$broken = join q{ }, map { $hyph->visualize($_) } split / /sm, $words;
is( q{ukes-kort-ene atten-de betre}, $broken, q{Norwegian} );

my $msg =
  'Author test. Set environment variable AUTHOR_TESTING} to enable this test.';
SKIP: {
    if ( not $ENV{'AUTHOR_TESTING'} ) {
        skip $msg, 1;
    }
}
$ENV{'AUTHOR_TESTING'} && Test::NoWarnings::had_no_warnings();

1;
