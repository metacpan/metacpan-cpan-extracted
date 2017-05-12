use Test::More tests => 9;
use Test::NoWarnings;
use Parse::BBCode;
use strict;
use warnings;

my %tag_def_html = (

    code   => {
        parse => 0,
        code => sub {
            my ($self, $attr, $content) = @_;
            "<code>$$content</code>"
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
    return $str =~ m{\[/?\w+\]} ? 1 : 0;
}

my @tests = (
        [ q#[c][a][/b]test#, q#[c][a][/b]test# ],
        [ q#[a][/b]#, q#[a][/b]# ],
        [ q#[a][b][/a][/b]#, q#<a>[b]</a>[/b]# ],
        [ q#[code]foo#, q#[code]foo# ],
        [ q#[code#, q#[code# ],
        [ q#[code foo bar#, q#[code foo bar# ],
        [ q#[a][code][/a][/code]#, q#[a]<code>[/a]</code># ],
        [ q#[b][a][code][/a][/code]#, q#[b][a]<code>[/a]</code># ],
);

for (@tests){
    my ($in, $exp) = @$_;
    my $parsed = $bbc2html->render($in);
    #warn __PACKAGE__.':'.__LINE__.": $in => $parsed\n";
    is($parsed, $exp, "unbalanced $in");
}
