#!/usr/bin/env perl

use strict;
use Test::More tests => 34;

BEGIN { use_ok('Search::Tools::UTF8') }

use Data::Dump qw( dump );

my $latin1 = 'ÈÉÊÃ ¾ ´ ª æ';

ok( !is_valid_utf8($latin1),   "latin1 is not utf8" );
ok( !is_ascii($latin1),        "latin1 is not ascii" );
ok( !is_flagged_utf8($latin1), "latin1 is not flagged utf8" );
ok( is_latin1($latin1),        "latin1 correctly identified" );
ok( is_sane_utf8($latin1),
    "latin1 is sane utf8 - doesn't claim to be utf8 and doesn't look like it"
);

# now break some stuff
my $nonsense
    = 'æ ascii ã“';    # 1st byte is latin1, last 3 bytes are valid utf8

#diag("nonsense = " . dump( $nonsense ));

ok( !is_valid_utf8($nonsense), "nonsense is not utf8" );
ok( !is_ascii($nonsense),      "nonsense is not ascii" );
ok( !is_latin1($nonsense),     "nonsense is not latin1" );
is( find_bad_utf8($nonsense),   $nonsense, "find_bad_utf8" );
is( find_bad_ascii($nonsense),  0,         "find_bad_ascii" );
is( find_bad_latin1($nonsense), 9,         "find_bad_latin1" );

my $ambiguous = "this string is ambiguous \x{d9}\x{a6}";

#diag("ambiguous = " . dump( $ambiguous ));

ok( is_valid_utf8($ambiguous),             "is_valid_utf8 ambiguous" );
ok( is_latin1($ambiguous),                 "is_latin1 ambiguous" );
ok( !defined( find_bad_utf8($ambiguous) ), "find_bad_utf8 ambiguous" );
is( find_bad_latin1($ambiguous), -1, "find_bad_latin1 ambiguous" );

my $moreamb = "this string should break is_latin1 \x{c3}\x{81}";

#diag("moreamb = " . dump( $moreamb ) );

ok( is_valid_utf8($moreamb),             "is_valid_utf8 moreamb" );
ok( !is_latin1($moreamb),                "!is_latin1 moreamb" );
ok( !defined( find_bad_utf8($moreamb) ), "find_bad_utf8 moreamb" );
is( find_bad_latin1_report($moreamb), 36, "find_bad_latin1_report moreamb" );

ok( !defined( find_bad_utf8('PC') ), "find_bad_utf8 allows ascii" );

# to_utf8 under 5.10
my $five10     = "foobar";
my %testhash   = ( $five10 => 1 );
my $five10utf8 = to_utf8($five10);
is( $five10, $five10utf8, "5.10 utf8 upgrade" );
ok( exists $testhash{$five10utf8}, "5.10 utf8 upgrade hash key" );

# now reverse it
my $five10utf8v2 = to_utf8("bar");
my %test2hash = ( $five10utf8v2 => 1 );
ok( exists $test2hash{"bar"}, "utf8 downgrade hash key" );

# cp1252 chars
my $cp1252 = "Euro sign = \x{80}";
ok( my $bad_latin1 = find_bad_latin1_report($cp1252),
    "find bad latin1 in cp1252" );
is( $bad_latin1, 12, "find bad latin1 bytes in cp1252 string" );

#####################################################################
#
# cp1252 tests
#

my $cp1251_codepoints      = "what\x92s a person";
my $cp1251_codepoints_utf8 = "what\xc2\x92s a person";
my $cp1251_codepoints_utf8_decoded
    = Encode::decode( 'cp1252', $cp1251_codepoints_utf8 );

#Search::Tools::describe( \$cp1251_codepoints_utf8 );
#Search::Tools::describe( \$cp1251_codepoints_utf8_decoded );
ok( is_valid_utf8($cp1251_codepoints_utf8),
    "$cp1251_codepoints_utf8 is valid utf8"
);
ok( looks_like_cp1252($cp1251_codepoints_utf8),
    "$cp1251_codepoints_utf8 looks like 1252"
);
ok( looks_like_cp1252($cp1251_codepoints),
    "real cp1252 encoded string looks like it"
);
ok( is_perl_utf8_string($cp1251_codepoints_utf8),
    "$cp1251_codepoints_utf8 is_perl_utf8_string"
);
my $cp1251_codepoints_utf8_double = to_utf8($cp1251_codepoints_utf8);
ok( is_perl_utf8_string($cp1251_codepoints_utf8_double),
    "cp1251_codepoints_utf8_double is_perl_utf8_string"
);

#Search::Tools::describe( \$more1252_utf8 );

#$Search::Tools::UTF8::Debug = 1;
ok( my $cp1251_codepoints_utf8_fixed
        = fix_cp1252_codepoints_in_utf8($cp1251_codepoints_utf8),
    "fix_cp1252_codepoints_in_utf8"
);

is( $cp1251_codepoints_utf8_fixed, to_utf8("what\x{2019}s a person"),
    "fix 1252" );
is( $cp1251_codepoints_utf8_fixed,
    to_utf8( $cp1251_codepoints, 'cp1252' ),
    "cp1251_codepoints_utf8_fixed cmp to_utf8(\$cp1251_codepoints, cp1252)"
);

#$Search::Tools::UTF8::Debug = 0;

if ( $ENV{PERL_TEST} ) {
    diag("cp1251_codepoints_utf8 $cp1251_codepoints_utf8");
    debug_bytes($cp1251_codepoints_utf8);
    diag("cp1251_codepoints_utf8_double $cp1251_codepoints_utf8_double");
    debug_bytes($cp1251_codepoints_utf8_double);
    diag("cp1251_codepoints_utf8_decoded $cp1251_codepoints_utf8_decoded");
    debug_bytes($cp1251_codepoints_utf8_decoded);
    diag("cp1251_codepoints_utf8_fixed $cp1251_codepoints_utf8_fixed");
    debug_bytes($cp1251_codepoints_utf8_fixed);
}
