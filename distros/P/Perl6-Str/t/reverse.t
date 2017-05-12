use strict;
use warnings;

use Test::More tests => 8;
use lib '../lib';
use lib 'lib';
binmode STDOUT, ':utf8';

use charnames qw(:full);

use Perl6::Str;
use Perl6::Str::Test qw(is_eq);


my @tests = (
    ["abc", "cba"],
    ["A\N{COMBINING ACUTE ACCENT}\N{COMBINING DIAERESIS}O",
        "OA\N{COMBINING ACUTE ACCENT}\N{COMBINING DIAERESIS}"],
    ["", ""],
    ["A\N{COMBINING DIAERESIS}", "A\N{COMBINING DIAERESIS}"],
);


for my $spec (@tests){
    my ($source, $expected) = @$spec;

    my $s = Perl6::Str->new($source);
    my $r = $s->reverse;
    is_eq $r, $expected,   "'$source'->reverse";
    is_eq $s, $source,     "'$source' unchanged";
}
