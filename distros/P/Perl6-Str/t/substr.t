use strict;
use warnings;
use Test::More tests => 104;
use Unicode::Normalize qw(NFD);
use lib '../lib';
use lib 'lib';

use charnames qw(:full);

use Perl6::Str::Test qw(expand_str);
use Perl6::Str;

# TODO: test also with characters for which no pre-defined 
# composition character exists

my $a = '\N{LATIN SMALL LETTER A WITH DIAERESIS}';
my $o = '\N{LATIN SMALL LETTER O WITH DIAERESIS}';
my $u = '\N{LATIN SMALL LETTER U WITH DIAERESIS}';
my ($ga, $go, $gu) = map { NFD($_) } $a, $o, $u;

my @tests = (
    # expected, source, @args_to_substr
    
    # 1 arg, ascii
    [ 'abc', 'abc', 0],
    [ 'bc',  'abc', 1],
    [ 'c',   'abc', 2],
    [ '',    'abc', 3],
    [ 'abc', 'abc', -3],
    [ 'bc',  'abc', -2],
    [ 'c',   'abc', -1],
    # 1 arg, codepoints
    [ "$a$o$u", "$a$o$u", 0],
    [ "$o$u",   "$a$o$u", 1],
    [ "$u",     "$a$o$u", 2],
    [ '',       "$a$o$u", 3],
    [ "$a$o$u", "$a$o$u", -3],
    [ "$o$u",   "$a$o$u", -2],
    [ "$u",     "$a$o$u", -1],
    # 1 arg, graphemes
    [ "$ga$go$gu", "$ga$go$gu", 0],
    [ "$go$gu",    "$ga$go$gu", 1],
    [ "$gu",       "$ga$go$gu", 2],
    [ '',          "$ga$go$gu", 3],
    [ "$ga$go$gu", "$ga$go$gu", -3],
    [ "$go$gu",    "$ga$go$gu", -2],
    [ "$gu",       "$ga$go$gu", -1],
    # 1 arg, mixed composed and decomposed characters
    # previous section, with random g's deleted
    [ "$a$go$u",   "$a$go$u", 0],
    [ "$go$gu",    "$ga$o$gu", 1],
    [ "$gu",       "$ga$o$gu", 2],
    [ '',          "$ga$o$gu", 3],
    [ "$ga$go$u",  "$ga$o$gu", -3],
    [ "$o$gu",     "$ga$o$gu", -2],
    [ "$gu",       "$ga$o$gu", -1],

    # 2 args, ascii
    [ 'abc', 'abc', 0, 3],
    [ 'ab' , 'abc', 0, 2],
    [ 'a',   'abc', 0, 1],
    [ '',    'abc', 0, 0],
    [ 'bc',  'abc', 1, 2],
    [ 'b',   'abc', 1, 1],
    [ '',    'abc', 1, 0],
    [ 'c',   'abc', 2, 1],
    [ '',    'abc', 2, 0],
    [ 'abc', 'abc', -3, 3],
    [ 'ab' , 'abc', -3, 2],
    [ 'a',   'abc', -3, 1],
    [ '',    'abc', -3, 0],
    [ 'bc',  'abc', -2, 2],
    [ 'b',   'abc', -2, 1],
    [ '',    'abc', -2, 0],
    [ 'c',   'abc', -1, 1],
    [ '',    'abc', -1, 0],

    # 2 args, codepoints
    [ "$a$o$u", "$a$o$u", 0, 3],
    [ "$a$o",   "$a$o$u", 0, 2],
    [ "$a",     "$a$o$u", 0, 1],
    [ "",       "$a$o$u", 0, 0],
    [ "$o$u",   "$a$o$u", 1, 2],
    [ "$o",     "$a$o$u", 1, 1],
    [ "",       "$a$o$u", 1, 0],
    [ "$u",     "$a$o$u", 2, 1],
    [ "",       "$a$o$u", 2, 0],
    [ "$a$o$u", "$a$o$u", -3, 3],
    [ "$a$o",   "$a$o$u", -3, 2],
    [ "$a",     "$a$o$u", -3, 1],
    [ "",       "$a$o$u", -3, 0],
    [ "$o$u",   "$a$o$u", -2, 2],
    [ "$o",     "$a$o$u", -2, 1],
    [ "",       "$a$o$u", -2, 0],
    [ "$u",     "$a$o$u", -1, 1],
    [ "",       "$a$o$u", -1, 0],

    # 2 args, graphemes
    [ "$ga$go$gu", "$ga$go$gu", 0, 3],
    [ "$ga$go",    "$ga$go$gu", 0, 2],
    [ "$ga",       "$ga$go$gu", 0, 1],
    [ "",          "$ga$go$gu", 0, 0],
    [ "$go$gu",    "$ga$go$gu", 1, 2],
    [ "$go",       "$ga$go$gu", 1, 1],
    [ "",          "$ga$go$gu", 1, 0],
    [ "$gu",       "$ga$go$gu", 2, 1],
    [ "",          "$ga$go$gu", 2, 0],
    [ "$ga$go$gu", "$ga$go$gu", -3, 3],
    [ "$ga$go",    "$ga$go$gu", -3, 2],
    [ "$ga",       "$ga$go$gu", -3, 1],
    [ "",          "$ga$go$gu", -3, 0],
    [ "$go$gu",    "$ga$go$gu", -2, 2],
    [ "$go",       "$ga$go$gu", -2, 1],
    [ "",          "$ga$go$gu", -2, 0],
    [ "$gu",       "$ga$go$gu", -1, 1],
    [ "",          "$ga$go$gu", -1, 0],

    # 2 args, mixed composition
    [ "$ga$go$gu", "$ga$o$gu", 0, 3],
    [ "$a$go",     "$ga$o$gu", 0, 2],
    [ "$ga",       "$ga$o$gu", 0, 1],
    [ "",          "$ga$o$gu", 0, 0],
    [ "$go$gu",    "$ga$o$gu", 1, 2],
    [ "$o",        "$ga$o$gu", 1, 1],
    [ "",          "$ga$o$gu", 1, 0],
    [ "$gu",       "$a$o$gu",  2, 1],
    [ "",          "$ga$o$gu", 2, 0],
    [ "$ga$go$gu", "$ga$o$gu", -3, 3],
    [ "$ga$o",     "$ga$o$gu", -3, 2],
    [ "$ga",       "$ga$o$u",  -3, 1],
    [ "",          "$ga$o$gu", -3, 0],
    [ "$go$u",     "$ga$o$gu", -2, 2],
    [ "$o",        "$a$o$gu",  -2, 1],
    [ "",          "$a$o$gu",  -2, 0],
    [ "$gu",       "$ga$o$gu", -1, 1],
    [ "",          "$ga$o$gu", -1, 0],

    # 3 args (substitutions)
    # TODO: more tests needed
    # return val,  source,   offset, length, repl, result
    [ 'cd',        'abcde',       2,  2,     '_',  'ab_e'],
    [ '',          'abcde',       -3, 0,     '_',  'ab_cde'],
);

for my $spec (@tests) {
    my $expected = shift @$spec;
    my $source   = shift @$spec;
    my $x = Perl6::Str->new(expand_str($source));
    my $e_expected = expand_str $expected;
    if (@$spec <= 2) {
        my $s = $x->substr(@$spec);

        ok(($s eq $e_expected), qq{->substr(@$spec) eq "$expected"}) 
            || diag "'$s' not equal '$expected'";
    } else {
#        warn "Testing 4 arg substr with '$x'\n";
        my $expected_result = pop @$spec;
        ok(($x->substr(@$spec) eq $e_expected),
                qq{->substr(@$spec) eq "$expected"}); 
        ok(($x eq expand_str($expected_result)),
                qq{->substr(@$spec) eq $expected_result}) || diag "$x" ;
    }
}
