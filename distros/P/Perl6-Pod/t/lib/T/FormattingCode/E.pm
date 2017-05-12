#===============================================================================
#
#  DESCRIPTION:  Entities code
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::E;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use base 'TBase';


sub t01_as_xhtml : Test {
    my $t= shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
Text  E<lt> E<gt> E<nbsp> E<laquo> E<lt;gt>
T
    ok $x =~ /&laquo;/;
}

sub t03_as_xhtml : Test {
    my $t= shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
sd E< lt ; LEFT DOUBLE ANGLE BRACKET >
T
    ok $x =~ /&lt;&#12298;/;
}
1;

