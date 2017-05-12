use strict;
use Test::More;
BEGIN { plan tests => 10 }
use Syntax::Highlight::HTML;

my $highlighter = new Syntax::Highlight::HTML;
my $expected = '';

## testing an empty string
is( $highlighter->parse(''), "<pre>\n</pre>\n"                ); #01

## testing a doctype declaration
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #02
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
ORIGINAL
<pre>
<span class="h-decl">&lt;!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"&gt;</span>
</pre>
EXPECTED

## testing a XML processing instruction
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #03
<?xml version="1.0" encoding="iso-8859-1"?>
ORIGINAL
<pre>
<span class="h-pi">&lt;?xml version="1.0" encoding="iso-8859-1"?&gt;</span>
</pre>
EXPECTED

## testing a SGML comment
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #04
<!-- This is a classic SGML coment -->
ORIGINAL
<pre>
<span class="h-com">&lt;!-- This is a classic SGML coment --&gt;</span>
</pre>
EXPECTED

## testing an HTML <p>
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #05
<p>Hello, world.</p>
ORIGINAL
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>Hello, world.<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED

## testing an HTML <p>, indented
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #06
    <p>Hello, world.</p>
ORIGINAL
<pre>
    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>Hello, world.<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED

## testing an XHTML <br/>
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #07
<br/>
ORIGINAL
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">br/</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED

## testing an XHTML <br/>, mixed case
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #08
<br/><Br/><bR/><BR/>
ORIGINAL
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">br/</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">Br/</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">bR/</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">BR/</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED

## testing an HTML <a>
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #09
<a href="http://www.maddingue.org/">Maddingue's web site</a>
ORIGINAL
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"http://www.maddingue.org/</span>"<span class="h-ab">&gt;</span>Maddingue's web site<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED

## testing an HTML <a>, splitted on several lines
is( $highlighter->parse(<<'ORIGINAL'), $expected=<<'EXPECTED' ); #10
<a href="http://www.maddingue.org/" 
    title="Maddingue's web site"
    lang="fr,en" type="text/html"
  >Maddingue's web site</a>
ORIGINAL
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"http://www.maddingue.org/</span>" 
    <span class="h-attr">title</span>=<span class="h-attv">"Maddingue's web site</span>"
    <span class="h-attr">lang</span>=<span class="h-attv">"fr,en</span>" <span class="h-attr">type</span>=<span class="h-attv">"text/html</span>"
  <span class="h-ab">&gt;</span>Maddingue's web site<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
</pre>
EXPECTED
