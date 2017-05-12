#===============================================================================
#
#  DESCRIPTION:  test lists
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::Block::item;
use strict;
use warnings;
use base 'TBase';
use Test::More;
use Data::Dumper;

sub t1_test_multi_para : Test(9) {
    my $t = shift;
    my $x = $t->parse_to_test( <<T1, );
=begin pod
=item # i1
=begin item2
parar1

para2
=end item2
=defn TEST
some para
=begin defn
     
term
definition for the term.

=end defn
=for item1 :!numbered
test
=end pod
T1
    my ($i1, $i2, $i3) = @{$x->{item}};
    ok $i1->is_numbered, ':numbered by # ';
    is $i1->item_level(),1, 'default level';
    is $i2->item_level(),2, '=item2 level';
    is $i1->item_type, 'ordered', 'item_type: ordered';
    is $i2->item_type, 'unordered', 'item_type: unordered';
    is $i3->item_type, 'unordered', 'item_type: :!numbered';
    my ($d1, $d2, $d3) = @{$x->{defn}};
    is $d1->item_type, 'definition', 'item_type: definition';
    is $d1->{term}, 'TEST', 'cut term =defn TERM';
    is $d2->{term}, 'term', 'cut term as first line';
}

sub t2_numbering_symbol : Test(1) {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T1, );
=begin pod
=item # i1
i2
=item # i2
=end pod
T1
    $t->is_deeply_xml(
        $x,
q# <xhtml xmlns="http://www.w3.org/1999/xhtml"><ol><li>i1
 i2
 </li><li>i2
 </li></ol></xhtml>
#
    );
}

sub t3_numbering_symbol : Test(1) {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T1, );
=begin pod
=item # i1
i2
=item # i2

=defn TERM1
Test
=end pod
T1
    $t->is_deeply_xml(
        $x,
q#<chapter><orderedlist><listitem>i1
 i2
</listitem><listitem>i2
 </listitem></orderedlist><variablelist><varlistentry>TERM1</varlistentry><listitem>Test
 </listitem></variablelist></chapter>
#
    );
}

sub t4_numbering_symbol : Test(1) {
   my $t = shift;
    my $x = $t->parse_to_xhtml( <<T1, );
=begin pod
=config item2 :numbered
=item1 test
=for item2 :a
one
=item2 two
=end pod
T1
    $t->is_deeply_xml(
        $x,
q# <xhtml xmlns="http://www.w3.org/1999/xhtml"><ul><li>test
 </li></ul><blockquote><ol><li>one
 </li><li>two
 </li></ol></blockquote></xhtml>
#
    );
}

sub t5_latex : Test(2) {
   my $t = shift;
    my $x = $t->parse_to_latex( <<T1, );
=begin pod
=config item2 :numbered
=item1 test
=for item2 :a
one
=item2 two
=end pod
T1
    ok $x =~ m%\\begin\{itemize\}%, 'itemized list';
    ok $x =~ m%\\begin\{enumerate\}%, 'numbered list';
}

1;
