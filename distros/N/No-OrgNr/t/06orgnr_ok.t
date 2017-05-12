#!/usr/bin/env perl

use utf8;
use 5.014;
use warnings;
use charnames qw/:full/;
use open qw/:encoding(UTF-8) :std/;

use Test::More;

BEGIN {
    use_ok( 'No::OrgNr', qw/orgnr_ok/ );
}

# Testing invalid org numbers
ok( !orgnr_ok('abc'),         'Testing invalid organization number (1)' );
ok( !orgnr_ok(''),            'Testing invalid organization number (2)' );
ok( !orgnr_ok(' '),           'Testing invalid organization number (3)' );
ok( !orgnr_ok(undef),         'Testing invalid organization number (4)' );
ok( !orgnr_ok('010 000 000'), 'Testing invalid organization number (5)' );
ok( !orgnr_ok('110 000 000'), 'Testing invalid organization number (6)' );
ok( !orgnr_ok('210 000 000'), 'Testing invalid organization number (7)' );
ok( !orgnr_ok('310 000 000'), 'Testing invalid organization number (8)' );
ok( !orgnr_ok('410 000 000'), 'Testing invalid organization number (9)' );
ok( !orgnr_ok('510 000 000'), 'Testing invalid organization number (10)' );
ok( !orgnr_ok('610 000 000'), 'Testing invalid organization number (11)' );
ok( !orgnr_ok('710 000 000'), 'Testing invalid organization number (12)' );

# Control digit = 10
ok( !orgnr_ok('987 770 970'), 'Testing invalid organization number (13)' );

# Wrong control digit
ok( !orgnr_ok('988 588 269'), 'Testing invalid organization number (14)' );

# Testing valid org numbers
my $orgnr       = '988588261';
my $valid_orgnr = '988 588 261';
is( orgnr_ok($orgnr),               $valid_orgnr, 'Testing valid organization number (1)' );
is( orgnr_ok('988588261'),          $valid_orgnr, 'Testing valid organization number (2)' );
is( orgnr_ok('  988  588  261  '),  $valid_orgnr, 'Testing valid organization number (3)' );
is( orgnr_ok('988 588 261'),        $valid_orgnr, 'Testing valid organization number (4)' );
is( orgnr_ok(' 9 8 8 5 8 8 2 6 1'), $valid_orgnr, 'Testing valid organization number (5)' );

# Testing organization number ending in a zero
$orgnr       = '999281370';
$valid_orgnr = '999 281 370';
is( orgnr_ok($orgnr), $valid_orgnr, 'Testing valid organization number (6)' );

# Verifying that a Bengali digit (U+09EA), which looks like the digit 8, is not allowed
my $non_ascii_digit = "\N{BENGALI DIGIT FOUR}";
my $test_nr         = '98' . $non_ascii_digit . '588261';
ok( !orgnr_ok($test_nr), 'Testing valid organization number with non-ASCII digit (1)' );

# Testing another non-ASCII Unicode digit 8 (U+1D7EA)
$non_ascii_digit = "\N{MATHEMATICAL SANS-SERIF DIGIT EIGHT}";
$test_nr         = '98' . $non_ascii_digit . '588261';
ok( !orgnr_ok($test_nr), 'Testing valid organization number with non-ASCII digit (2)' );

done_testing;
