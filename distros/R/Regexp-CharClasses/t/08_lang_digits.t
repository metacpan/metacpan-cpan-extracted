#!/usr/bin/perl

use Test::More tests => 1421;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

use charnames ':full';

my @languages = map {s/^\s+//; $_} split /\n/ => <<"--";
    ARABIC-INDIC
    EXTENDED ARABIC-INDIC
    NKO
    DEVANAGARI
    BENGALI
    GURMUKHI
    GUJARATI
    ORIYA
    TAMIL
    TELUGU
    KANNADA
    MALAYALAM
    THAI
    LAO
    TIBETAN
    MYANMAR
    KHMER
    MONGOLIAN
    LIMBU
    NEW TAI LUE
    BALINESE
    OSMANYA
    FULLWIDTH
    MATHEMATICAL BOLD
    MATHEMATICAL DOUBLE-STRUCK
    MATHEMATICAL SANS-SERIF
    MATHEMATICAL SANS-SERIF BOLD
    MATHEMATICAL MONOSPACE
--

my @numbers = qw [ZERO  ONE   TWO   THREE FOUR
                  FIVE  SIX   SEVEN EIGHT NINE];

foreach my $language (@languages) {
    my $lang = join "" => map {ucfirst lc} split /\W+/ => $language;
    my $pat  = "\\p{Is${lang}Digit}";
    my $Pat  = "\\P{Is${lang}Digit}";
    
    foreach my $num (@numbers) {
        my $name = "$language DIGIT $num";
        my $str  =  eval qq ["\\N{$name}"];
        ok $str  =~ /^$pat/,  qq ["\\N{$name}" =~ /^$pat\$/];
        ok $str  !~ /^$Pat/,  qq ["\\N{$name}" !~ /^$Pat\$/];
        ok $str  =~ /^\P{IsLatinDigit}$/,
                qq ["\\N{$name}" =~ /^\\P{IsLatinDigit}\$/];
    }
}

foreach (0 .. 9) {
    ok  /^\p{IsLatinDigit}$/, qq ["$_" =~ /^\\p{IsLatinDigit}\$/];
    ok !/^\P{IsLatinDigit}$/, qq ["$_" =~ /^\\P{IsLatinDigit}\$/];

    foreach my $language (@languages) {
        my $lang = join "" => map {ucfirst lc} split /\W+/ => $language;
        my $pat  = "\\p{Is${lang}Digit}";
        my $Pat  = "\\P{Is${lang}Digit}";

        ok !/^$pat$/, qq ["$_" =~ /^$pat\$/];
        ok  /^$Pat$/, qq ["$_" !~ /^$pat\$/];
    }
}

__END__
