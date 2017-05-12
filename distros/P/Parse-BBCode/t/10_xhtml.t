use Test::More tests => 22;
use Test::NoWarnings;
use Parse::BBCode::XHTML;
use strict;
use warnings;

eval {
    require
        Email::Valid;
};
my $email_valid = $@ ? 0 : 1;
#$email_valid = 0;

my $parser = Parse::BBCode::XHTML->new();

my @tests = (
    [ q#[B]bold? [test#,
        q#[B]bold? [test# ],
    [ q#[i=23]italic [b]bold italic <html>[/b][/i]# . "$/$/",
        q#<i>italic <b>bold italic &lt;html&gt;</b></i><br /># ],
    [ q#[U][noparse]<html>[u][c][/noparse][/u]# . "$/$/",
        q#<u>&lt;html&gt;[u][c]</u><br /># ],
    [ q#[img=/foo.jpg]desc <html>[/img]#,
        q#<img src="/foo.jpg" alt="[desc &lt;html&gt;]" title="desc &lt;html&gt;" /># ],
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
    [ q#[quote=who]cite[/quote]#,
        q#<div class="bbcode_quote_header">who:<div class="bbcode_quote_body">cite</div></div># ],
    [ q#[code]use strict;[/code]#,
        q#<div class="bbcode_code_header">Code:<div class="bbcode_code_body">use strict;</div></div># ],
    [ q#[noparse]foo[b][/noparse]#,
        q#foo[b]# ],
    [ q#[code]foo[code]bar<html>[/code][/code]#,
        q#<div class="bbcode_code_header">Code:<div class="bbcode_code_body">foo[code]bar&lt;html&gt;</div></div>[/code]# ],
    [ q#[i]italic [b]bold italic <html>[/i][/b]#,
        q#<i>italic [b]bold italic &lt;html&gt;</i>[/b]# ],
    [ q#[i]italic [b]bold italic <html>[/i][/b]#,
        q#[i]italic <b>bold italic &lt;html&gt;[/i]</b>#, 'i' ],
);
for my $test (@tests) {
    my ($text, $exp, $forbid) = @$test;
    if ($forbid) {
        $parser->forbid($forbid);
    }
    my $parsed = $parser->render($text);
    #warn __PACKAGE__.':'.__LINE__.": $parsed\n";
    s/[\r\n]//g for ($exp, $parsed);
    $text =~ s/[\r\n]//g;
    cmp_ok($parsed, 'eq', $exp, "parse '$text'");
    if ($forbid) {
        $parser->permit($forbid);
    }
}

