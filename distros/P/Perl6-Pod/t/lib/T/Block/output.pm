#===============================================================================
#
#  DESCRIPTION:  test output block
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$

package  T::Block::output;
use strict;
use warnings;
use Test::More;
use base 'TBase';


sub p02_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml(<<T);
=begin pod

=output
  1.2.3
  sdsd sd sd sd

=end pod
T

$t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><pre><samp>  1.2.3
   sdsd sd sd sd
 </samp></pre></xhtml>#
    );
}

sub p03_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook(<<T);
=begin pod
=output
  1.2.3
  sdsd sd sd sd

=end pod
T
$t->is_deeply_xml(
        $x,
q# <chapter><screen>  1.2.3
   sdsd sd sd sd
 </screen></chapter>#
    );
}


1;

