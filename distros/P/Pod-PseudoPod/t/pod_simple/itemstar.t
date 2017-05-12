
use strict;
use Test;
BEGIN { plan tests => 6 };

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../../blib/lib';
    unshift @INC, '../../lib';
}

#my $d;
#use Pod::Simple::Debug (3);

ok 1;

use Pod::PseudoPod::DumpAsXML;
use Pod::PseudoPod::XMLOutStream;
print "# Pod::PseudoPod version $Pod::PseudoPod::VERSION\n";
sub e ($$) { Pod::PseudoPod::DumpAsXML->_duo(@_) }

my $x = 'Pod::PseudoPod::XMLOutStream';

print "##### Tests for '=item * Foo' tolerance via class $x\n";

$Pod::PseudoPod::XMLOutStream::ATTR_PAD   = ' ';
$Pod::PseudoPod::XMLOutStream::SORT_ATTRS = 1; # for predictably testable output


print "#\n# Tests for simple =item *'s\n";
ok( $x->_out("\n=over\n\n=item * Stuff\n\n=item * Bar I<baz>!\n\n=back\n\n"),
    '<Document><over-bullet indent="4"><item-bullet>Stuff</item-bullet><item-bullet>Bar <I>baz</I>!</item-bullet></over-bullet></Document>'
);
ok( $x->_out("\n=over\n\n=item * Stuff\n\n=cut\n\nStuff\n\n=item *\n\nBar I<baz>!\n\n=back\n\n"),
    '<Document><over-bullet indent="4"><item-bullet>Stuff</item-bullet><item-bullet>Bar <I>baz</I>!</item-bullet></over-bullet></Document>'
);
ok( $x->_out("\n=over 10\n\n=item * Stuff\n\n=cut\n\nStuff\n\n=item *\n\nBar I<baz>!\n\n=back\n\n"),
    '<Document><over-bullet indent="10"><item-bullet>Stuff</item-bullet><item-bullet>Bar <I>baz</I>!</item-bullet></over-bullet></Document>'
);
ok( $x->_out("\n=over\n\n=item * Stuff I<things\num> hoo!\n=cut\nStuff\n\n=item *\n\nBar I<baz>!\n\n=back"),
    '<Document><over-bullet indent="4"><item-bullet>Stuff <I>things um</I> hoo!</item-bullet><item-bullet>Bar <I>baz</I>!</item-bullet></over-bullet></Document>'
);




print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";


