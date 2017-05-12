#===============================================================================
#
#  DESCRIPTION:  test Z<>
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::FormattingCode::Z;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';

sub t01_as_xml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
The Z<TWEST>
T
is $x,q#<xhtml xmlns="http://www.w3.org/1999/xhtml"><p>The 
</p></xhtml>#;
}

1;



