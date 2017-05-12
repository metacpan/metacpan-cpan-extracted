
use strict;
use Test;
BEGIN { plan tests => 18 };

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../../blib/lib';
    unshift @INC, '../../lib';
}

#use Pod::Simple::Debug (5);

ok 1;

use Pod::PseudoPod::DumpAsXML;
use Pod::PseudoPod::XMLOutStream;
print "# Pod::PseudoPod version $Pod::PseudoPod::VERSION\n";
sub e ($$) { Pod::PseudoPod::DumpAsXML->_duo(@_) }

print "# With weird leading whitespace...\n";
# With weird whitespace
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nI<foo>\n"),
 '<Document><Para><I>foo</I></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB< foo>\n"),
 '<Document><Para><B> foo</B></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB<\tfoo>\n"),
 '<Document><Para><B> foo</B></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB<\nfoo>\n"),
 '<Document><Para><B> foo</B></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB<foo>\n"),
 '<Document><Para><B>foo</B></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB<foo\t>\n"),
 '<Document><Para><B>foo </B></Para></Document>'
);
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nB<foo\n>\n"),
 '<Document><Para><B>foo </B></Para></Document>'
);


print "#\n# Tests for wedges outside of formatting codes...\n";
&ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nX < 3 and N > 19\n"),
     Pod::PseudoPod::XMLOutStream->_out("=pod\n\nX E<lt> 3 and N E<gt> 19\n")
);


print "# A complex test with internal whitespace...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nI<foo>B< bar>C<baz >F< quux\t?>\n"),
 '<Document><Para><I>foo</I><B> bar</B><C>baz </C><F> quux ?</F></Para></Document>'
);


print "# Without any nesting...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nF<a>C<b>I<c>B<d>X<e>\n"),
 '<Document><Para><F>a</F><C>b</C><I>c</I><B>d</B><X>e</X></Para></Document>'
);

print "# Without any nesting, but with Z's...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nZ<>F<a>C<b>I<c>B<d>X<e>\n"),
 '<Document><Para><F>a</F><C>b</C><I>c</I><B>d</B><X>e</X></Para></Document>'
);


print "# With lots of nesting, and Z's...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nZ<>F<C<Z<>foo> I<bar>> B<X<thingZ<>>baz>\n"),
 '<Document><Para><F><C>foo</C> <I>bar</I></F> <B><X>thing</X>baz</B></Para></Document>'
);



print "#\n# *** Now testing different numbers of wedges ***\n";
print "# Without any nesting...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nF<< a >>C<<< b >>>I<<<< c >>>>B<< d >>X<< e >>\n"),
 '<Document><Para><F>a</F><C>b</C><I>c</I><B>d</B><X>e</X></Para></Document>'
);

print "# Without any nesting, but with Z's, and odder whitespace...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nF<< aZ<> >>C<<< Z<>b >>>I<<<< c  >>>>B<< d \t >>X<<\ne >>\n"),
 '<Document><Para><F>a</F><C>b</C><I>c</I><B>d</B><X>e</X></Para></Document>'
);

print "# With nesting and Z's, and odder whitespace...\n";
ok( Pod::PseudoPod::XMLOutStream->_out("=pod\n\nF<< aZ<> >>C<<< Z<>bZ<>B<< d \t >>X<<\ne >> >>>I<<<< c  >>>>\n"),
 '<Document><Para><F>a</F><C>b<B>d</B><X>e</X></C><I>c</I></Para></Document>'
);


print "# Misc...\n";
ok( Pod::PseudoPod::XMLOutStream->_out(
 "=pod\n\nI like I<PIE> with B<cream> and Stuff and N < 3 and X<< things >> hoohah\n"
."And I<pie is B<also> a happy time>.\n"
."And B<I<<< I like pie >>>.>\n"
) =>
"<Document><Para>I like <I>PIE</I> with <B>cream</B> and Stuff and N &#60; 3 and <X>things</X> hoohah "
."And <I>pie is <B>also</B> a happy time</I>. "
."And <B><I>I like pie</I>.</B></Para></Document>"
);





print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";


