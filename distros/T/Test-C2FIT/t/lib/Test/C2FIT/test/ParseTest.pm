# Copyright (c) 2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.

package Test::C2FIT::test::ParseTest;

use base 'Test::Unit::TestCase';
use strict;

use Error qw( :try );

use Test::C2FIT::Parse;

#===============================================================================================
# Public Methods
#===============================================================================================

sub test_parsing
{
	my $self = shift;
	my $p = new Test::C2FIT::Parse("leader<Table foo=2>body</table>trailer", ["table"]);
	$self->assert_str_equals("leader", $p->leader());
	$self->assert_str_equals("<Table foo=2>", $p->tag());
	$self->assert_str_equals("body", $p->body());
	$self->assert_str_equals("trailer", $p->trailer());
}

sub test_recursing
{
	my $self = shift;
	my $p = new Test::C2FIT::Parse("leader<table><TR><Td>body</tD></TR></table>trailer");
	$self->assert_null($p->body());
	$self->assert_null($p->parts->body());
	$self->assert_str_equals("body", $p->parts()->parts()->body());
}

sub test_iterating
{
	my $self = shift;
	my $p = new Test::C2FIT::Parse("leader<table><tr><td>one</td><td>two</td><td>three</td></tr></table>trailer");
	$self->assert_str_equals("one", $p->parts()->parts()->body());
	$self->assert_str_equals("two", $p->parts()->parts()->more()->body());
	$self->assert_str_equals("three", $p->parts()->parts()->more()->more()->body());
}

sub test_indexing
{
	my $self = shift;
	my $p = new Test::C2FIT::Parse("leader<table><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>four</td></tr></table>trailer");
	$self->assert_str_equals("one", 	$p->at(0,0,0)->body());
	$self->assert_str_equals("two", 	$p->at(0,0,1)->body());
	$self->assert_str_equals("three", 	$p->at(0,0,2)->body());
	$self->assert_str_equals("three", 	$p->at(0,0,3)->body());
	$self->assert_str_equals("three", 	$p->at(0,0,4)->body());
	$self->assert_str_equals("four",	$p->at(0,1,0)->body());
	$self->assert_str_equals("four",	$p->at(0,1,1)->body());
	$self->assert_str_equals("four",	$p->at(0,2,0)->body());
	$self->assert_equals(1, $p->size());
	$self->assert_equals(2, $p->parts->size());
	$self->assert_equals(3, $p->parts->parts->size());
	$self->assert_str_equals("one",		$p->leaf()->body());
	$self->assert_str_equals("four",	$p->parts->last()->leaf()->body());
}

sub test_parse_exception
{
	my $self = shift;
	my $exception;
	try
	{
		my $p = new Test::C2FIT::Parse("leader<table><tr><th>one</th><th>two</th><th>three</th></tr><tr><td>four</td></tr></table>trailer");
	} 
	catch Test::C2FIT::ParseException with
	{
		$exception = shift;
		$self->assert_equals(17, $exception->getErrorOffset());
		$self->assert_str_equals("Can't find tag: td", $exception->getMessage());
	};
	$self->assert($exception, "exptected exception not thrown");
}

sub test_text
{
	my $self = shift;
	my @tags = ("td");

	my $p = new Test::C2FIT::Parse("<td>a&lt;b</td>", \@tags);
	$self->assert_str_equals("a&lt;b", $p->body());
	$self->assert_str_equals("a<b", $p->text());
	$p = new Test::C2FIT::Parse("<td>\ta&gt;b&nbsp;&amp;&nbsp;b>c &&&lt;</td>", \@tags);
	$self->assert_str_equals("a>b & b>c &&<", $p->text());
	$p = new Test::C2FIT::Parse("<td>\ta&gt;b&nbsp;&amp;&nbsp;b>c &&lt;</td>", \@tags);
	$self->assert_str_equals("a>b & b>c &<", $p->text());
	$p = new Test::C2FIT::Parse("<TD><P><FONT FACE=\"Arial\" SIZE=2>GroupTestFixture</FONT></TD>", \@tags);
	$self->assert_str_equals("GroupTestFixture",$p->text());

	$self->assert_str_equals("", Test::C2FIT::Parse->htmlToText("&nbsp;"));
	$self->assert_str_equals("a b", Test::C2FIT::Parse->htmlToText("a <tag /> b"));
	$self->assert_str_equals("a", Test::C2FIT::Parse->htmlToText("a &nbsp;"));
	$self->assert_str_equals("&nbsp;", Test::C2FIT::Parse->htmlToText("&amp;nbsp;"));

	$self->assert_str_equals("1     2", Test::C2FIT::Parse->htmlToText("1 &nbsp; &nbsp; 2"));
	$self->assert_str_equals("1     2", Test::C2FIT::Parse->htmlToText("1 \x{00a0}\x{00a0}\x{00a0}\x{00a0}2"));
	$self->assert_str_equals("a", Test::C2FIT::Parse->htmlToText("  <tag />a"));
	$self->assert_str_equals("a\nb", Test::C2FIT::Parse->htmlToText("a<br />b"));

	$self->assert_str_equals("ab", Test::C2FIT::Parse->htmlToText("<font size=+1>a</font>b"));
	$self->assert_str_equals("ab", Test::C2FIT::Parse->htmlToText("a<font size=+1>b</font>"));
	$self->assert_str_equals("a<b", Test::C2FIT::Parse->htmlToText("a<b"));

	$self->assert_str_equals("a\nb\nc\nd", Test::C2FIT::Parse->htmlToText("a<br>b<br/>c<  br   /   >d"));
	$self->assert_str_equals("a\nb", Test::C2FIT::Parse->htmlToText("a</p><p>b"));
	$self->assert_str_equals("a\nb", Test::C2FIT::Parse->htmlToText("a< / p >   <   p  >b"));
	$self->assert_str_equals("a\nb", Test::C2FIT::Parse->htmlToText("a< / p >\n<   p  >b"));

	#$self->assert_str_equals("a\nb", Test::C2FIT::Parse->htmlToText("<p>a</p><p>b</p>"));

}

sub test_unescape
{
	my $self = shift;
	$self->assert_str_equals("a<b", Test::C2FIT::Parse->unescape("a&lt;b"));
	$self->assert_str_equals("a>b & b>c &&", Test::C2FIT::Parse->unescape("a&gt;b&nbsp;&amp;&nbsp;b>c &&"));
	$self->assert_str_equals("&amp;&amp;", Test::C2FIT::Parse->unescape("&amp;amp;&amp;amp;"));
	$self->assert_str_equals("a>b & b>c &&", Test::C2FIT::Parse->unescape("a&gt;b&nbsp;&amp;&nbsp;b>c &&"));
	$self->assert_str_equals('""', Test::C2FIT::Parse->unescape("\x{201c}\x{201d}"));
	$self->assert_str_equals("''", Test::C2FIT::Parse->unescape("\x{2018}\x{2019}"));

}

sub test_whitespace_is_condensed
{
	my $self = shift;
	$self->assert_str_equals("a b",	Test::C2FIT::Parse->condenseWhitespace(" a  b  "));
	$self->assert_str_equals("a b",	Test::C2FIT::Parse->condenseWhitespace(" a  \n\tb  "));
	$self->assert_str_equals("", 	Test::C2FIT::Parse->condenseWhitespace(" "));
	$self->assert_str_equals("", 	Test::C2FIT::Parse->condenseWhitespace("  "));
	$self->assert_str_equals("",	Test::C2FIT::Parse->condenseWhitespace("   "));
	$self->assert_str_equals("",	Test::C2FIT::Parse->condenseWhitespace(chr(160)));

	$self->assert_str_equals("a b",	Test::C2FIT::Parse->condenseWhitespace("a&nbsp;b"));
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;

__END__

package fit;

//Copyright (c) 2002 Cunningham & Cunningham, Inc.
//Released under the terms of the GNU General Public License version 2 or later.

import junit.framework.TestCase;

public class ParseTest extends TestCase {

	public ParseTest(String name) {
		super(name);
	}
	
	public void testParsing () throws Exception {
		Parse p = new Parse("leader<Table foo=2>body</table>trailer", new String[] {"table"});
		assertEquals("leader", p.leader);
		assertEquals("<Table foo=2>", p.tag);
		assertEquals("body", p.body);
		assertEquals("trailer", p.trailer);
	}
	    
	public void testRecursing () throws Exception {
		Parse p = new Parse("leader<table><TR><Td>body</tD></TR></table>trailer");
		assertEquals(null, p.body);
		assertEquals(null, p.parts.body);
		assertEquals("body", p.parts.parts.body);
	}
    
	public void testIterating () throws Exception {
		Parse p = new Parse("leader<table><tr><td>one</td><td>two</td><td>three</td></tr></table>trailer");
		assertEquals("one", p.parts.parts.body);
		assertEquals("two", p.parts.parts.more.body);
		assertEquals("three", p.parts.parts.more.more.body);
	}
    
	public void testIndexing () throws Exception {
		Parse p = new Parse("leader<table><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>four</td></tr></table>trailer");
		assertEquals("one", p.at(0,0,0).body);
		assertEquals("two", p.at(0,0,1).body);
		assertEquals("three", p.at(0,0,2).body);
		assertEquals("three", p.at(0,0,3).body);
		assertEquals("three", p.at(0,0,4).body);
		assertEquals("four", p.at(0,1,0).body);
		assertEquals("four", p.at(0,1,1).body);
		assertEquals("four", p.at(0,2,0).body);
		assertEquals(1, p.size());
		assertEquals(2, p.parts.size());
		assertEquals(3, p.parts.parts.size());
		assertEquals("one", p.leaf().body);
		assertEquals("four", p.parts.last().leaf().body);
	}
	
	public void testParseException () {
		try {
			Parse p = new Parse("leader<table><tr><th>one</th><th>two</th><th>three</th></tr><tr><td>four</td></tr></table>trailer");
		} catch (java.text.ParseException e) {
			assertEquals(17, e.getErrorOffset());
			assertEquals("Can't find tag: td", e.getMessage());
			return;
		}
		fail("exptected exception not thrown");
	}

	public void testText () throws Exception {
		String tags[] ={"td"};
		Parse p = new Parse("<td>a&lt;b</td>", tags);
		assertEquals("a&lt;b", p.body);
		assertEquals("a<b", p.text());
		p = new Parse("<td>\ta&gt;b&nbsp;&amp;&nbsp;b>c &&&lt;</td>", tags);
		assertEquals("a>b & b>c &&<", p.text());
		p = new Parse("<td>\ta&gt;b&nbsp;&amp;&nbsp;b>c &&lt;</td>", tags);
		assertEquals("a>b & b>c &<", p.text());
		p = new Parse("<TD><P><FONT FACE=\"Arial\" SIZE=2>GroupTestFixture</FONT></TD>", tags);
		assertEquals("GroupTestFixture",p.text());
		
		assertEquals("", Parse.htmlToText("&nbsp;"));
		assertEquals("a b", Parse.htmlToText("a <tag /> b"));
		assertEquals("a", Parse.htmlToText("a &nbsp;"));
		assertEquals("&nbsp;", Parse.htmlToText("&amp;nbsp;"));
		assertEquals("1     2", Parse.htmlToText("1 &nbsp; &nbsp; 2"));
		assertEquals("1     2", Parse.htmlToText("1 \u00a0\u00a0\u00a0\u00a02"));
		assertEquals("a", Parse.htmlToText("  <tag />a"));
		assertEquals("a\nb", Parse.htmlToText("a<br />b"));

		assertEquals("ab", Parse.htmlToText("<font size=+1>a</font>b"));
		assertEquals("ab", Parse.htmlToText("a<font size=+1>b</font>"));
		assertEquals("a<b", Parse.htmlToText("a<b"));

		assertEquals("a\nb\nc\nd", Parse.htmlToText("a<br>b<br/>c<  br   /   >d"));
		assertEquals("a\nb", Parse.htmlToText("a</p><p>b"));
		assertEquals("a\nb", Parse.htmlToText("a< / p >   <   p  >b"));
	}

	public void testUnescape () {
		assertEquals("a<b", Parse.unescape("a&lt;b"));
		assertEquals("a>b & b>c &&", Parse.unescape("a&gt;b&nbsp;&amp;&nbsp;b>c &&"));
		assertEquals("&amp;&amp;", Parse.unescape("&amp;amp;&amp;amp;"));
		assertEquals("a>b & b>c &&", Parse.unescape("a&gt;b&nbsp;&amp;&nbsp;b>c &&"));
		assertEquals("\"\"'", Parse.unescape("“”’"));
	}

	public void testWhitespaceIsCondensed() {
		assertEquals("a b", Parse.condenseWhitespace(" a  b  "));
		assertEquals("a b", Parse.condenseWhitespace(" a  \n\tb  "));
		assertEquals("", Parse.condenseWhitespace(" "));
		assertEquals("", Parse.condenseWhitespace("  "));
		assertEquals("", Parse.condenseWhitespace("   "));
		assertEquals("", Parse.condenseWhitespace(new String(new char[]{(char) 160})));
	}
}
