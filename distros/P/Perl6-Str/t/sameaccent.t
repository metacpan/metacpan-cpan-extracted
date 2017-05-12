use strict;
use warnings;
use Test::More tests => 6;
use charnames qw(:full);
binmode STDERR, ':utf8';

use lib '../lib';
use lib 'lib';
use Perl6::Str;
use Perl6::Str::Test qw(expand_str);

my $acute = '\N{COMBINING ACUTE ACCENT}';
my $dia   = '\N{COMBINING DIAERESIS}';
my $a_a   = '\N{LATIN SMALL LETTER A WITH ACUTE}';
my $a_d   = '\N{LATIN SMALL LETTER A WITH DIAERESIS}';
my $o_a   = '\N{LATIN SMALL LETTER O WITH ACUTE}';
my $o_d   = '\N{LATIN SMALL LETTER O WITH DIAERESIS}';
my $u_a   = '\N{LATIN SMALL LETTER U WITH ACUTE}';
my $u_d   = '\N{LATIN SMALL LETTER U WITH DIAERESIS}';

my @tests = (
    [ 'abc',        ' ',            'abc' ],
    [ 'abc',        '',             'abc' ],
    [ "$a_a|a",     'abc',          'a|a' ],
    [ "$a_a|$a_d",  'abc',          'a|a' ],
    [ "aou",        "$o_a $a_d",    "${a_a}o$u_d"],
    [ 'ao\N{COMBINING HOOK ABOVE}u', "$o_a $a_d",    "${a_a}o$u_d"],
);

for my $spec (@tests){
    my ($source, $pattern, $result) = @$spec;
    my $s = Perl6::Str->new(expand_str $source);

    ok(($s->sameaccent(expand_str $pattern) eq expand_str $result), 
            "'$source'->samecase($pattern) eq '$result'");

}
