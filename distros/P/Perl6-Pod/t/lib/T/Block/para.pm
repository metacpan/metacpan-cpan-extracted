#===============================================================================
#
#  DESCRIPTION:  test =para block
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::Block::para;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


sub p03_multi_para_xhtml :Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml(<<T);
=begin pod
=begin para
    B<test> and I<test>

    Simple para I<test>
=end para
=end pod
T

$t->is_deeply_xml ( $x, q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>    <strong>test</strong> and <em>test</em></p><p>    Simple para <em>test</em>
 </p></xhtml>#
 )

}

sub p03_multi_para_docbook :Test {
    my $t = shift;
    my $x = $t->parse_to_docbook(<<T);
=begin pod
=begin para
B<test> and I<test>

Simple para I<test>
=end para
=end pod
T

$t->is_deeply_xml ( $x, q#<?xml version="1.0"?>
<chapter>
  <para><emphasis role="bold">test</emphasis> and <emphasis role="italic">test</emphasis></para>
  <para>    Simple para <emphasis role="italic">test</emphasis>
</para>
</chapter>
#
 )

}

sub p03_multi_para_latex :Test {
    my $t = shift;
    my $x = $t->parse_to_latex(<<T);
=begin pod
=begin para
B<test> and I<test>

Simple para I<test>
=end para
=end pod
T

  ok $x =~ m%\\textbf\{test\} and \\emph\{test\}%, 'latex'
}


1;


