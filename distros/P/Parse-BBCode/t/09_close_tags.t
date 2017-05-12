use Test::More tests => 20;
use Test::NoWarnings;
use Parse::BBCode;
use strict;
use warnings;

my $p = Parse::BBCode->new({
        tags => {
            '' => sub { Parse::BBCode::escape_html($_[2]) },
            i   => '<i>%s</i>',
            b   => '<b>%{parse}s</b>',
            size => '<font size="%a">%{parse}s</font>',
            url => '<a href="%{link}A">%{parse}s</a>',
            quote => 'block:<quote>%{parse}s</quote>',
            noparse => '%{html}s',
        },
        close_open_tags => 1,
    }
);

my @tests = (
    [ 1, q#[i]italic[b]bold [quote]this is invalid[/quote] bold[/b][/i]#,
         q#<i>italic<b>bold </b></i><quote>this is invalid</quote> bold[/b][/i]#,
         q#[i]italic[b]bold [/b][/i][quote]this is invalid[/quote] bold[/b][/i]#,
         ],
    [ 0, q#[i]italic[b]bold [quote]this is invalid[/quote] bold[/b][/i]#,
         q#[i]italic[b]bold <quote>this is invalid</quote> bold[/b][/i]#,
         q#[i]italic[b]bold [quote]this is invalid[/quote] bold[/b][/i]#,
         ],
    [ 0, q#[i]italic[b]bold[/b] [quote]this is invalid[/quote] [/i]#,
         q#[i]italic<b>bold</b> <quote>this is invalid</quote> [/i]#,
         q#[i]italic[b]bold[/b] [quote]this is invalid[/quote] [/i]#,
         ],
    [ 1, q#[i]italic[b]bold [url]/foo[/url]#,
         q#<i>italic<b>bold <a href="/foo">/foo</a></b></i>#,
         q#[i]italic[b]bold [url]/foo[/url][/b][/i]#,
    ],
    [ 1, q#[b][i]italic#,
         q#<b><i>italic</i></b>#,
         q#[b][i]italic[/i][/b]#,
    ],
    [ 1, q#[b][i]italic[/b]#,
         q#<b><i>italic</i></b>#,
         q#[b][i]italic[/i][/b]#,
    ],
    [ 0, q#[noparse][b][i]italic[/i][/b]#,
         q#[noparse]<b><i>italic</i></b>#,
         q#[noparse][b][i]italic[/i][/b]#,
    ],
    [ 1, q#[noparse][b][i]italic[/i][/b]#,
         q#[b][i]italic[/i][/b]#,
         q#[noparse][b][i]italic[/i][/b][/noparse]#,
    ],
   [ 1, q#[noparse][i]italic#,
        q#[i]italic#,
        q#[noparse][i]italic[/noparse]#,
   ],
   [ 1, q#[quote][noparse][i]italic#,
        q#<quote>[i]italic</quote>#,
        q#[quote][noparse][i]italic[/noparse][/quote]#,
   ],

);

for (@tests) {
    my ($close, $in, $exp, $exp_raw) = @$_;
    $p->set_close_open_tags($close);
    my $parsed = $p->render($in);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    my $close_string = $close ? 'yes' : 'no';
    cmp_ok($parsed, 'eq', $exp, "invalid (close? $close_string) $in");
    my $err = $p->error('block_inline') || $p->error('unclosed');
    if ($err) {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$err], ['err']);
        my $tree = $p->get_tree;
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tree], ['tree']);
        my $raw = $tree->raw_text;
        #warn __PACKAGE__.':'.__LINE__.": $raw\n";
        cmp_ok($raw, 'eq', $exp_raw, "raw text (close? $close_string) $in");
    }
}

