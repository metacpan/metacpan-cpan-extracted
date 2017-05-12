#===============================================================================
#
#  DESCRIPTION:  Replaceable item
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::FormattingCode::R;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use base 'TBase';


sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
Name: R<your surname>
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Name: <var>your surname</var>
</p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Name: R<your surname>
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><para>Name: <replaceable>your surname</replaceable>
</para></chapter>
#
    );
}

1;

