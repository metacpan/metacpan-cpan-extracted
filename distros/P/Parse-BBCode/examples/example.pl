#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Parse::BBCode;

my %tag_def_html = (

    code   => {
        code => sub {
            my $c = $_[2];
            $c = Parse::BBCode::escape_html($$c);
            "<code>$c</code>"
        },
    },
    perlmonks => 'url:<a href="http://www.perlmonks.org/?node=%{uri|html}a">%{parse}s</a>',
    url => 'url:<a href="%{link}a">%{parse}s</a>',
    i   => '<i>%{parse}s</i>',
    b   => '<b>%{parse}s</b>',
);

my $bbc2html = Parse::BBCode->new({                                                              
        tags => {
            %tag_def_html,
        },
    }
);

my $text = <<'EOM';
[i]italic [b]bold italic <html>[/b][/i]
[perlmonks=123]foo <html>[i]italic[/i][/perlmonks]
[url=javascript:alert(123)]foo <html>[i]italic[/i][/url]
[code]foo[b][/code]
[code]foo[code]bar<html>[/code][/code]
[i]italic [b]bold italic <html>[/i][/b]
[b]bold?
EOM


my $parsed = $bbc2html->render($text);
print "$parsed\n";

__DATA__
<i>italic <b>bold italic &lt;html&gt;</b></i><br>
<a href="http://www.perlmonks.org/?node=123">foo &lt;html&gt;<i>italic</i></a><br>
<a href="">foo &lt;html&gt;<i>italic</i></a><br>
<code>foo[b]</code><br>
<code>foo[code]bar&lt;html&gt;[/code]</code><br>
<i>italic [b]bold italic &lt;html&gt;</i>[/b]<br>
[b]bold?<br>
