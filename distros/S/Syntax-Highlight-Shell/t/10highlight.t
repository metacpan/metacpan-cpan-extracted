use strict;
use Test::More;
BEGIN { plan tests => 9 }
use Syntax::Highlight::Shell;

my $highlighter = new Syntax::Highlight::Shell;
my $expected = '';

## testing an empty string
is( $highlighter->parse(''), "<pre>\n</pre>\n"                ); #01

## shebang (no end-of-line)
is( $highlighter->parse('#!/bin/sh'), <<'HTML'                ); #02
<pre>
<span class="s-cmt">#!/bin/sh</span></pre>
HTML

## shebang
is( $highlighter->parse("#!/bin/sh\n"), <<'HTML'              ); #03
<pre>
<span class="s-cmt">#!/bin/sh</span>
</pre>
HTML

## comment
is( $highlighter->parse("# a comment\n"), <<'HTML'            ); #04
<pre>
<span class="s-cmt"># a comment</span>
</pre>
HTML

## keyword
is( $highlighter->parse('for'), <<'HTML'                      ); #05
<pre>
<span class="s-key">for</span></pre>
HTML

## builtin
is( $highlighter->parse('eval'), <<'HTML'                     ); #06
<pre>
<span class="s-blt">eval</span></pre>
HTML

## expanded variable
is( $highlighter->parse('$variable'), <<'HTML'                ); #07
<pre>
<span class="s-var">$variable</span></pre>
HTML

## assigned variable
is( $highlighter->parse('variable_01=any_value'), <<'HTML'    ); #08
<pre>
<span class="s-avr">variable_01</span>=<span class="s-val">any_value</span></pre>
HTML

## value between quotes
is( $highlighter->parse('"any kind of value"'), <<'HTML'      ); #09
<pre>
<span class="s-quo">"</span><span class="s-val">any kind of value</span><span class="s-quo">"</span></pre>
HTML

