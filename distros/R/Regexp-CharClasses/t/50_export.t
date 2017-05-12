#!/usr/bin/perl

use Test::More tests => 324;

use strict;
use warnings;
no warnings 'syntax';

my @digits  = qw [IsDigit0 IsDigit1 IsDigit2 IsDigit3 IsDigit4
                  IsDigit5 IsDigit6 IsDigit7 IsDigit8 IsDigit9
                  IsLatinDigit IsArabicIndicDigit
                  IsExtendedArabicIndicDigit IsNkoDigit IsDevanagariDigit
                  IsGurmukhiDigit IsOriyaDigit IsTamilDigit IsTeluguDigit
                  IsKannadaDigit IsMalayalamDigit IsThaiDigit IsLaoDigit
                  IsTibetanDigit IsMyanmarDigit IsKhmerDigit IsMongolianDigit
                  IsLimbuDigit IsNewTaiLueDigit IsBalineseDigit IsOsmanyaDigit
                  IsFullwidthDigit IsMathematicalBoldDigit
                  IsMathematicalDoubleStruckDigit IsMathematicalSansSerifDigit
                  IsMathematicalSansSerifBoldDigit
                  IsMathematicalMonospaceDigit];
my @perl    = qw [IsPerlSigil   IsLeftParen   IsRightParen IsParen];
my @english = qw [IsLcVowel     IsUcVowel     IsVowel
                  IsLcConsonant IsUcConsonant IsConsonant];
my @encode  = qw [IsUuencode IsBase64 IsBase64url IsBase32 IsBase32hex
                  IsBase16 IsBinHex];
my @all     = (@digits, @perl, @english, @encode);

package Test::digits;

use Regexp::CharClasses ':digits';

foreach my $digit (@digits) {
    no strict 'refs';
    Test::More::ok defined &{"Test::digits::$digit"}, "Imported $digit";
}
foreach my $thing (@perl, @english, @encode) {
    no strict 'refs';
    Test::More::ok !defined &{"Test::digits::$thing"}, "Imported $thing";
}

package Test::perl;

use Regexp::CharClasses ':perl';

foreach my $perl (@perl) {
    no strict 'refs';
    Test::More::ok defined &{"Test::perl::$perl"}, "Imported $perl";
}
foreach my $thing (@digits, @english, @encode) {
    no strict 'refs';
    Test::More::ok !defined &{"Test::perl::$thing"}, "Imported $thing";
}

package Test::english;

use Regexp::CharClasses ':english';

foreach my $english (@english) {
    no strict 'refs';
    Test::More::ok defined &{"Test::english::$english"}, "Imported $english";
}
foreach my $thing (@digits, @perl, @encode) {
    no strict 'refs';
    Test::More::ok !defined &{"Test::english::$thing"}, "Imported $thing";
}

package Test::encode;

use Regexp::CharClasses ':encode';

foreach my $english (@encode) {
    no strict 'refs';
    Test::More::ok defined &{"Test::encode::$english"}, "Imported $english";
}
foreach my $thing (@digits, @perl, @english) {
    no strict 'refs';
    Test::More::ok !defined &{"Test::encode::$thing"}, "Imported $thing";
}

package Test::all;

use Regexp::CharClasses;

foreach my $any (@all) {
    no strict 'refs';
    Test::More::ok defined &{"Test::all::$any"}, "Imported $any";
}

package Test::nothing;

use Regexp::CharClasses ();

foreach my $any (@all) {
    no strict 'refs';
    Test::More::ok !defined &{"Test::nothing::$any"}, "Not imported $any";
}

__END__
