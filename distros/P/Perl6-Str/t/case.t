use strict;
use warnings;
use Test::More tests => 42;
use charnames qw(:full);

use lib '../lib';
use lib 'lib';
use Perl6::Str;
use Perl6::Str::Test qw(is_eq);



my ($a, $o, $A, $O, $ga, $go, $gA, $gO) = (
        "\N{LATIN SMALL LETTER A WITH DIAERESIS}",
        "\N{LATIN SMALL LETTER O WITH DIAERESIS}",
        "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}",
        "\N{LATIN CAPITAL LETTER O WITH DIAERESIS}",
        "a\N{COMBINING DIAERESIS}",
        "o\N{COMBINING DIAERESIS}",
        "A\N{COMBINING DIAERESIS}",
        "O\N{COMBINING DIAERESIS}",
);

my @tests = (
    # source, uc, lc, ucfirst, lcfirst, capitalize
        
    # ASCII sanity
    [qw(aBcD ABCD abcd ABcD aBcD Abcd)],
    # a few codepoints
    [
        "\N{LATIN SMALL LETTER A WITH DIAERESIS}\N{LATIN SMALL LETTER O WITH DIAERESIS}", 
        "$A$O",
        "$a$o",
        "$A$o",
        "$a$o",
        "$A$o",
    ],
    [
        "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}\N{LATIN CAPITAL LETTER O WITH DIAERESIS}", 
        "$A$O",
        "$a$o",
        "$A$O",
        "$a$O",
        "$A$o",
    ],
    # other compositions
    [
        "A\N{COMBINING DIAERESIS}O\N{COMBINING DIAERESIS}",
        "$gA$gO",
        "$ga$go",
        "$gA$gO",
        "$ga$gO",
        "$gA$go",
    ],
    [
        "a\N{COMBINING DIAERESIS}o\N{COMBINING DIAERESIS}",
        "$gA$gO",
        "$ga$go",
        "$gA$go",
        "$ga$go",
        "$gA$go",
    ],
    # tests specially for capitalize
    [ "ab cd", "AB CD", "ab cd", "Ab cd", "ab cd", "Ab Cd"],
    [ "0a,bC", "0A,BC", "0a,bc", "0a,bC", "0a,bC", "0a,Bc"],
);

for my $spec (@tests){
    my ($source, $uc, $lc, $ucfirst, $lcfirst, $cap) = @$spec;

    my $x = Perl6::Str->new( $source );

    is_eq $x->uc,           $uc,        "uc of '$source'";
    is_eq $x->lc,           $lc,        "lc of '$source'";
    is_eq $x->ucfirst,      $ucfirst,   "ucfirst of '$source'";
    is_eq $x->lcfirst,      $lcfirst,   "lcfirst of '$source'";
    is_eq $x->capitalize,   $cap,       "capitalize of '$source'";

    is_eq $x,               $source,    "'$source' unchanged";
}
