#===============================================================================
#
#  DESCRIPTION:  Test :nested
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::Parser::NestedAttr;
use strict;
use warnings;
use base "TBase";
use Test::More;
use Data::Dumper;


sub f03_nested_attr_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T, );
=begin pod
=for para :nested(2)
test
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><blockquote><blockquote><p>test
</p></blockquote></blockquote></xhtml>#
    );
}

sub f04_nested_attr_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T, );
=begin pod
=for para :nested(2)
test
=end pod
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><blockquote><blockquote><para>test
</para></blockquote></blockquote></chapter>#
    );
}

1;

