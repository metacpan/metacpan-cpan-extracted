use Test::More tests => 8;
use Test::NoWarnings;
use Parse::BBCode;
use strict;
use warnings;

my %tag_def_html = (

    code   => {
        parse => 0,
        code => sub {
            "<code></code>"
        },
    },
    pre   => {
        code => sub {
            "<code></code>"
        },
    },
    a => '<a>%{parse}s</a>',
    b => '<b>%{parse}s</b>',
    c => '<c>%{parse}s</c>',
);

my $bbc2html = Parse::BBCode->new({                                                              
        tags => {
            %tag_def_html,
        },
    }
);

sub contains_untranslated {
    my $str = shift;
    $str =~ m/\[\w+\]/;
}

my @tests = (
    [q{[a][b][/b][/a]},                     q{<a><b></b></a>}],
    [q{[a][b][a][b][/b][/a][/b][/a]},       q{<a><b><a><b></b></a></b></a>}],
    [q{[a][a][a][/a][a][/a][/a][a][/a][/a]},q{<a><a><a></a><a></a></a><a></a></a>}],
    [q{[code][a][c][/code]},                q{<code></code>}],
    [q{[a][code][a][c][/code][/a]},         q{<a><code></code></a>}],
    [q{[a][code][/a][/code][/a]},           q{<a><code></code></a>}],
    [q{[a][b][code][/a][/b][c][/code][/b][/a]},q{<a><b><code></code></b></a>}],
);

for (@tests){
    my $parsed = $bbc2html->render($_->[0]);
    is $parsed, $_->[1], $_->[0];
}

