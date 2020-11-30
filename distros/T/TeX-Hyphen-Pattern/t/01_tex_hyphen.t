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

my %todos = (
    'Ar'                   => 'Arabic - has no hyphenation',
    'As'                   => 'Assamese',
    'Be'                   => 'Belarusian',
    'Bg'                   => 'Bulgarian',
    'Bg_t2a'               => 'Bulgarian t2a encoded',
    'Bn'                   => 'Bengali',
    'Cop'                  => 'Very experimental coptic for "copto" font',
    'Cu'                   => 'Church Slavonic',
    'El_monoton'           => 'Modern Monotonic Greek',
    'El_polyton'           => 'Modern Polytonic Greek',
    'Eo'                   => 'Esperanto',
    'Fa'                   => 'Persian - has no hyphenation',
    'Grc'                  => 'Ancient Greek',
    'Grc_x_ibycus'         => 'Ancient Greek in Ibycus encoding',
    'Gu'                   => 'Gujarati',
    'Hi'                   => 'Hindi',
    'Hy'                   => 'Armenian',
    'Ka'                   => 'Georgian',
    'Ka_t8m'               => 'Georgian t8m encoded',
    'Kn'                   => 'Kannada',
    'Mk'                   => 'Macedonian',
    'Ml'                   => 'Malayalam',
    'Mn_cyrl'              => 'Mongolian',
    'Mn_cyrl_t2a'          => 'Mongolian t2a encoded',
    'Mn_cyrl_x_lmc'        => 'Mongolian LMC encoded',
    'Mr'                   => 'Marathi',
    'Mul_ethi'             => 'Experimental Ethiopic',
    'Nb'                   => 'Norwegian Bokmål',
    'Nn'                   => 'Norwegian Nynorsk',
    'Or'                   => 'Oriya',
    'Pa'                   => 'Panjabi',
    'Ru'                   => 'Russian',
    'Ru_t2a'               => 'Russian t2a encoded',
    'Sh'                   => 'Serbocroatian',
    'Sh_cyrl'              => 'Serbocroatian in Cyrillic',
    'Sh_cyrl_t2a'          => 'Serbian in Cyrillic t2a encoded',
    'Sr'                   => 'Serbian',
    'Sr_cyrl'              => 'Serbian in Cyrillic',
    'Ta'                   => 'Tamil',
    'Te'                   => 'Telugu',
    'Th'                   => 'Thai',
    'Th_lth'               => 'Thai lth encoded',
    'Uk'                   => 'Ukranian',
    'Quote_af'             => 'Quote af',
    'Quote_be'             => 'Quote be',
    'Quote_fr'             => 'Quote fr',
    'Quote_fur'            => 'Quote fur',
    'Quote_it'             => 'Quote it',
    'Quote_oc'             => 'Quote oc',
    'Quote_pms'            => 'Quote pms',
    'Quote_rm'             => 'Quote rm',
    'Quote_uk'             => 'Quote uk',
    'Quote_zh_latn_pinyin' => 'Quote zh latn pinyin',
    'Utf8'                 => 'Utf-8',
);
use TeX::Hyphen::Pattern;
my $SPACE = q{ };
my $thp   = TeX::Hyphen::Pattern->new();

sub namespace_leaf {
    m/.*::(.*)/sxm;
    if ( defined $1 ) {
        return $1;
    }
}
my @labels =
  grep { not defined $todos{$_} } sort map { namespace_leaf } $thp->packaged;
my @todos =
  grep { defined $todos{$_} } sort map { namespace_leaf } $thp->packaged;

# Currently we test every pattern against a set of words and fail if a pattern
# doesn't manage to get a soft hyphen in. For every pattern that doesn't put a
# hyphen in a generic word we add a word suited for that pattern.
# But what if we had old pattern that worked and new patterns that are borken?
# Manually check the differences.

my %words = (
    'generic'       => 'Supercalifragilisticexpialidocious',
    'Icelandic'     => 'Upplýsingatæknifyrirtæki',
    'AncientGreek'  => 'ὀφειλήματα οφειλήματα',
    'Serbian'       => 'Реализовали',
    'Serbocroation' => 'уламжлалаа',
    'Sanskrit'      => 'देवनागरीदेवनागरी',
    'Russian'       => 'уламжлалаа',
    'ModernGreek'   => 'ὀφειλήματα οφειλήματα',
);
my $words = join $SPACE, values %words;

plan 'tests' => ( 0 + @labels + @todos ) + 1 + 1;
note( sprintf q{Number of patterns packaged: %d},  0 + $thp->packaged );
note( sprintf q{Number of patterns available: %d}, 0 + @labels );
isnt( 0 + @labels, 0, q{Number of patterns available} );
for my $label (@labels) {
    note($label);
    $thp->label($label);
    my $hyph   = TeX::Hyphen->new( $thp->filename );
    my $broken = join q{ }, map { $hyph->visualize($_) } split / /sm, $words;
    isnt( $words, $broken, qq{using pattern for '$label' in TeX::Hyphen} );
}
TODO: {
    local $TODO = q{Pattern seems to be incompatible with TeX::Hyphen engine};
    for my $label (@todos) {
        note($label);
        $thp->label($label);
        my $hyph   = TeX::Hyphen->new( $thp->filename );
        my $broken = join q{ }, map { $hyph->visualize($_) } split / /sm,
          $words;
        isnt( $words, $broken, qq{using pattern for '$label' in TeX::Hyphen} );
    }
}

my $msg =
  'Author test. Set environment variable AUTHOR_TESTING} to enable this test.';
SKIP: {
    if ( not $ENV{'AUTHOR_TESTING'} ) {
        skip $msg, 1;
    }
}
$ENV{'AUTHOR_TESTING'} && Test::NoWarnings::had_no_warnings();

1;
