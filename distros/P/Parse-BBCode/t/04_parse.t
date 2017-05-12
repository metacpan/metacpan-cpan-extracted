use Test::More tests => 86;
use Test::NoWarnings;
use Parse::BBCode;
use strict;
use warnings;

my %tag_def_html = (
    perlmonks => '<a href="http://www.perlmonks.org/?node=%{uri|html}a" rel="nofollow">%{parse}s</a>',
);
eval {
    require
        Email::Valid;
};
my $email_valid = $@ ? 0 : 1;
#$email_valid = 0;

my $bbc2html = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            %tag_def_html,
            'img'   => '<img src="%{html}A" alt="[%{html}s]" title="%{html}s" align="%{align}attr">',
        },
    }
);
my $bbc2html_sq = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            %tag_def_html,
            'img'   => '<img src="%{html}A" alt="[%{html}s]" title="%{html}s" align="%{align}attr">',
        },
        attribute_quote => q/'/,
    }
);
my $bbc2html_sdq = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            %tag_def_html,
            'img'   => '<img src="%{html}A" alt="[%{html}s]" title="%{html}s" align="%{align}attr">',
        },
        attribute_quote => q/'"/,
    }
);
my $bbc2html2 = Parse::BBCode->new({
        close_open_tags => 1,
    escapes => {
        Parse::BBCode::HTML->default_escapes,
    },
    });
my $bbc2html_block = Parse::BBCode->new({
        tags => {
            Parse::BBCode::HTML->defaults,
            %tag_def_html,
            '' => sub {
                my $outer = $_[1];
                my $block = $outer->get_class eq 'block' ? 1 : 0;
                my $text = Parse::BBCode::escape_html($_[2]);
                if ($block) {
                    $text =~ s[ (\r?\n|\r) (\r?\n|\r)* ]
                        [if ($2) { "</p><p>" } else { "<br>\n" } ]exg;
                }
                else {
                    $text =~ s[ (\r?\n|\r) ][<br>]xg;
                }
                $text;
            },
        },
    }
);
my $pns = Parse::BBCode->new({
        tags => {
            b => '<b>%s</b>',
        },
        strict_attributes => 0,
    }
);

my @tests = (
    [ q#[img://23]#,
        q#[img://23]# ],
    [ q#[img=foo align=center]test[/img]#,
        q#<img src="foo" alt="[test]" title="test" align="center"># ],
    [ q#[img=foo align='center']test[/img]#,
        q#<img src="foo" alt="[test]" title="test" align="center">#, undef, $bbc2html_sq ],
    [ q#[img=foo align='center']test[/img]#,
        q#<img src="foo" alt="[test]" title="test" align="center">#, undef, $bbc2html_sdq ],
    [ q#[img=foo align="center" ]test[/img]#,
        q#<img src="foo" alt="[test]" title="test" align="center"># ],
    [ q#[url=/test]foo[/url] bla [url=/test2]foo2[/url]#,
        q#<a href="/test" rel="nofollow">foo</a> bla <a href="/test2" rel="nofollow">foo2</a>#],
    [ q#[B]bold? [test#,
        q#[B]bold? [test# ],
    [ q#[B]bold[/B]#,
        q#<b>bold</b># ],
    [ q#[b]bold[/B]#,
        q#<b>bold</b># ],
    [ q#[b foo bar]bold[/B]#,
        q#<b>bold</b>#, undef, $pns],
    [ q#[i=23]italic [b]bold italic <html>[/b][/i]# . "$/$/",
        q#<i>italic <b>bold italic &lt;html&gt;</b></i><br># ],
    [ q#[U][noparse]<html>[u][c][/noparse][/u]# . "$/$/",
        q#<u>&lt;html&gt;[u][c]</u><br># ],
    [ q#[img=foo.jpg]desc <html>[/img]#,
        q#<img src="foo.jpg" alt="[desc &lt;html&gt;]" title="desc &lt;html&gt;" align=""># ],
    [ q#[url=javascript:alert(123)]foo <html>[i]italic[/i][/url]#,
        q#[url=javascript:alert(123)]foo &lt;html&gt;<i>italic</i>[/url]# ],
    [ q#[url=http://foo]foo <html>[i]italic[/i][/url]#,
        q#<a href="http://foo" rel="nofollow">foo &lt;html&gt;<i>italic</i></a># ],
    [ q#[email=no"mail]mail [i]me[/i][/email]#,
        $email_valid ? q#<a href="mailto:">mail <i>me</i></a># : q#<a href="mailto:no&quot;mail">mail <i>me</i></a># ],
    [ q#[email="test <foo@example.org>"]mail [i]me[/i][/email]#,
        $email_valid ? q#<a href="mailto:foo@example.org">mail <i>me</i></a># : q#<a href="mailto:test &lt;foo@example.org&gt;">mail <i>me</i></a>#],
    [ q#[email]test <foo@example.org>[/email]#,
        $email_valid ? q#<a href="mailto:foo@example.org">test &lt;foo@example.org&gt;</a># : q#<a href="mailto:test &lt;foo@example.org&gt;">test &lt;foo@example.org&gt;</a>#],
    [ q#[size=7]big[/size]#,
        q#<span style="font-size: 7">big</span># ],
    [ q#[size=huge!]big[/size]#,
        q#<span style="font-size: 0">big</span># ],
    [ q{[color=#0000FF]blue[/color]},
        q{<span style="color: #0000FF">blue</span>} ],
    [ q{[color="red"]blue[/color]},
        q{<span style="color: red">blue</span>} ],
    [ q{[color="no color!"]blue[/color]},
        q{<span style="color: inherit">blue</span>} ],
    [ q#[list][*]first[*]second[*]third[/list]#,
        q#<ul><li>first</li><li>second</li><li>third</li></ul># ],
    [ q#[quote=who]cite <>[/quote]#,
        q#<div class="bbcode_quote_header">who:<div class="bbcode_quote_body">cite &lt;&gt;</div></div># ],
    [ q#[code]use strict;[/code]#,
        q#<div class="bbcode_code_header">Code:<div class="bbcode_code_body">use strict;</div></div># ],
    [ q#[perlmonks=123]foo <html>[i]italic[/i][/perlmonks]# . "$/$/",
        q#<a href="http://www.perlmonks.org/?node=123" rel="nofollow">foo &lt;html&gt;<i>italic</i></a><br># ],
    [ q#[noparse]foo[b][/noparse]#,
        q#foo[b]# ],
    [ q#[noparse]foo[b][/NOPARSE]#,
        q#foo[b]# ],
    [ q#[code]foo[code]bar<html>[/code][/code]#,
        q#<div class="bbcode_code_header">Code:<div class="bbcode_code_body">foo[code]bar&lt;html&gt;</div></div>[/code]# ],
    [ q#[i]italic [b]bold italic <html>[/i][/b]#,
        q#<i>italic [b]bold italic &lt;html&gt;</i>[/b]#, undef, undef, 1 ],
    [ q#[i]italic [b]bold italic <html>[/i][/b]#,
        q#[i]italic <b>bold italic &lt;html&gt;[/i]</b>#, 'i' ],
    [ "outer\n\nnewline\n" . qq# [i]inner\n\nnewline[/i]#,
        q#outer</p><p>newline<br> <i>inner<br><br>newline</i>#, undef, $bbc2html_block ],
    [ qq#[url=http://foo/][url=http://bar/]test[/url][/url]#,
        q#<a href="http://foo/" rel="nofollow">[url=http://bar/]test</a>[/url]#, ],
    [ q#[url=relative]test[/url]#,
        q#[url=relative]test[/url]#, ],
    [ q#0#,
        q#0#, ],
    [ q# [] #,
        q# [] #, ],
    [ q#[b]test[/i]#,
        q#<b>test[/i]</b>#, undef, $bbc2html2, 1],
    [ q#[noparse="bar"]test[/noparse]#,
        q#test#],
    [ q#[noparse="bar" baz="boo"]test[/noparse]#,
        q#test#],
    [ q#[noparse="bar" bar="baz" baz="boo"]test[/noparse]#,
        q#test#],
);
for my $test (@tests) {
    my ($text, $exp, $forbid, $parser, $error) = @$test;
    $error = 0 unless defined $error;
    $parser ||= $bbc2html;
    if ($forbid) {
        $parser->forbid($forbid);
    }
    my $parsed = $parser->render($text);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    s/[\r\n]//g for ($exp, $parsed);
    $text =~ s/[\r\n]//g;
    cmp_ok($parser->get_error ? 1 : 0, '==', $error, "error $text");
    cmp_ok($parsed, 'eq', $exp, "parse '$text'");
    if ($forbid) {
        $parser->permit($forbid);
    }
}
eval {
    my $parsed = $bbc2html->render();
};
my $error = $@;
#warn __PACKAGE__.':'.__LINE__.": <<$@>>\n";
cmp_ok($error, '=~', 'Missing input', "Missing input for render()");

$bbc2html->permit('foobar');
my $allowed = $bbc2html->get_allowed;
#warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$allowed], ['allowed']);
ok(
    (!grep { $_ eq 'foobar' } @$allowed),
    "permit() an unsupported tag");

my %tags = Parse::BBCode->defaults;
my $bb1 = Parse::BBCode->new({ tags => \%tags });
my $bb2 = Parse::BBCode->new({ tags => \%tags });
my $render1 = $bb1->render("\n");
my $render2 = $bb2->render("\n");
cmp_ok($render2, 'eq', $render1, "don't change parameter hash");

