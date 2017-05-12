#===============================================================================
#
#  DESCRIPTION:  test B<> implementation
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$

package T::FormattingCode::B;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
Bold B<test>
T
    $t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Bold <strong>test</strong>
 </p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Bold B<test>
T
 $t->is_deeply_xml(
        $x,
q#<chapter><para>Bold <emphasis role='bold'>test</emphasis>
</para></chapter>#)
}

sub t03_as_latex : Test {
    my $t = shift;
    my $x = $t->parse_to_latex( <<T);
=para
Bold B<test>
T
ok $x =~ m%\\textbf\{test\}%
}

1;

