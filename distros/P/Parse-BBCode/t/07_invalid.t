#!/usr/bin/perl
use Test::More tests => 9;
use Test::NoWarnings;
use Parse::BBCode;
use strict;
use warnings;

my %tag_def_html = (

    code   => {
        parse => 0,
        code => sub {
            "<code>%{}s</code>"
        },
    },
    pre => {
        code => sub {
            "<code></code>"
        },
    },
    a => '<a>%{parse}s</a>',
    b => '<b>%{parse}s</b>',
    c => '<c>%{parse}s</c>',
);
my $p = Parse::BBCode->new({
        tags => {
            %tag_def_html,
        },
    }
);

my @tests = (
    [
        q#test [c=invalid bar]foo[b]inner[/b][/c][b]valid[/b]#,
        q#test <c>foo<b>inner</b></c><b>valid</b>#,
        q#test [c=invalid bar]foo<b>inner</b>[/c]<b>valid</b>#,
    ],
    [
        q#test [c=]foo[b]inner[/b][/c][b]valid[/b]#,
        q#test <c>foo<b>inner</b></c><b>valid</b>#,
        q#test [c=]foo<b>inner</b>[/c]<b>valid</b>#,
    ],
    [
        q#test [c]foo[b]inner[/b][/c][b]valid[/b]#,
        q#test <c>foo<b>inner</b></c><b>valid</b>#,
        q#test <c>foo<b>inner</b></c><b>valid</b>#,
    ],
    [
        q#test [c!invalid bar]foo[b]inner[/b][/c][b]valid[/b]#,
        q#test [c!invalid bar]foo<b>inner</b>[/c]<b>valid</b>#,
        q#test [c!invalid bar]foo<b>inner</b>[/c]<b>valid</b>#,
    ],
);

for my $strict (0 .. 1) {
    $p->set_strict_attributes($strict);
    for (@tests) {
        my ($in) = @$_;
        my $exp = $strict ? $_->[2] : $_->[1];
        my $parsed = $p->render($in);
        #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
        cmp_ok($parsed, 'eq', $exp, "$in");
    }
}
