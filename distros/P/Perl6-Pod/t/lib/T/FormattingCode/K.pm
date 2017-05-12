#===============================================================================
#
#  DESCRIPTION:  Test K<> code
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::FormattingCode::K;
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
Do you want additional personnel details? K<y>
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Do you want additional personnel details? <kbd>y</kbd>
</p></xhtml>
#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Do you want additional personnel details? K<y>
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><para>Do you want additional personnel details? <userinput>y</userinput>
</para></chapter>
#
    );
}

1;



