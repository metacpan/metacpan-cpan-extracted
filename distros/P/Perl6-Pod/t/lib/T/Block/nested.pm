#===============================================================================
#
#  DESCRIPTION:  test block =nested
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$

package T::Block::nested;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


sub c02_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook(<<T);
=begin pod
=begin nested
=begin nested
Test B<er>
=end nested
=end nested
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<?xml version="1.0"?>
<chapter>
  <blockquote>
    <blockquote>
      <para>Test <emphasis role="bold">er</emphasis>
</para>
    </blockquote>
  </blockquote>
</chapter>
#
    );
}

sub c02_as_xhml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml(<<T);
=begin pod
=begin nested
=begin nested
Test B<er>
=end nested
=end nested
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<?xml version="1.0"?>
<xhtml xmlns="http://www.w3.org/1999/xhtml">
  <blockquote>
    <blockquote>
      <p>Test <strong>er</strong>
</p>
    </blockquote>
  </blockquote>
</xhtml>
#
    );
}
1;
