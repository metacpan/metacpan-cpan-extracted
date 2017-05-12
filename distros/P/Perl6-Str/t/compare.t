use strict;
use warnings;
use Test::More tests => 3 * 14;
use lib '../lib';
use lib 'lib';

use charnames qw(:full);

use Perl6::Str;
use Perl6::Str::Test qw(expand_str);


my @tests = (
    # basic sanity
    ['abc', 'abc', 'eq'],
    ['a',   'b',   'lt'],
    ['a',   'b',   'ne'],
    ['a',   'b',   'le'],
    # grapehme level
    ['A\N{COMBINING DIAERESIS}', 
        '\N{LATIN CAPITAL LETTER A WITH DIAERESIS}', 'eq'],

    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'ne'],
    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'lt'],
    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'le'],

    ['A\N{COMBINING DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'ne'],
    ['A\N{COMBINING DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'lt'],
    ['A\N{COMBINING DIAERESIS}',
        '\N{LATIN CAPITAL LETTER O WITH DIAERESIS}', 'le'],

    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{COMBINING DIAERESIS}', 'ne'],
    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{COMBINING DIAERESIS}', 'lt'],
    ['\N{LATIN CAPITAL LETTER A WITH DIAERESIS}',
        '\N{COMBINING DIAERESIS}', 'le'],
);

for my $test_spec (@tests){
    my ($a, $b, $cmp) = @$test_spec;
    my $sa = expand_str $a;
    my $sb = expand_str $b;

    my $p6a = Perl6::Str->new($sa);
    my $p6b = Perl6::Str->new($sb);
#    warn "$p6a $cmp $p6b\n";

    ok eval "\$p6a $cmp \$p6b", "$a $cmp $b (p6, p6)";
    ok eval "\$sa  $cmp \$p6b", "$a $cmp $b (p5, p6)";
    ok eval "\$p6a $cmp \$sb",  "$a $cmp $b (p6, p5)";
}
