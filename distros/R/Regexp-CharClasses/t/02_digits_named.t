#!/usr/bin/perl

use Test::More tests => 2901;

use strict;
use warnings;
no warnings 'syntax';

BEGIN {
    use_ok ('Regexp::CharClasses')
};

use charnames ':full';

my @names = map {s/^\s+//; $_} split /\n/ => <<"--";
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
    FULLWIDTH
    OSMANYA
    MATHEMATICAL BOLD
    MATHEMATICAL DOUBLE-STRUCK
    MATHEMATICAL SANS-SERIF
    MATHEMATICAL SANS-SERIF BOLD
    MATHEMATICAL MONOSPACE
--
unshift @names => "";

my @numbers = qw [ZERO  ONE   TWO   THREE FOUR
                  FIVE  SIX   SEVEN EIGHT NINE];

for (my $index = 0; $index < @numbers; $index ++) {
    my $number = $numbers [$index];

    foreach my $digit (@names) {
        my $name = $digit ? "$digit DIGIT $number" : "DIGIT $number";
        my $str  = eval qq ["\\N{$name}"];
        my $pat  = "\\p{IsDigit$index}";
        ok $str  =~ /^$pat$/, qq ["\\N{$name}" =~ /^$pat\$/];

        for (my $j = 0; $j < @numbers; $j ++) {
            next if $j == $index;
            my $pat    = "\\P{IsDigit$j}";
            ok $str    =~ /^$pat$/, qq ["\\N{$name}" =~ /^$pat\$/];
        }
    }
}


__END__
