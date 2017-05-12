#===============================================================================
#
#  DESCRIPTION:  test S<>
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::S;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use base 'TBase';

sub t01_as_xml : Test {
    my $t = shift;
    my $x = $t->parse_to_xml( <<T);
=para
The emergency signal is: S<
dot dot dot   dash dash dash   dot dot dot>.
T
is $x,q#<para pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'>The emergency signal is: <S pod:type='code'>
dot dot dot   dash dash dash   dot dot dot</S>.
</para>#;
}

sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
The emergency signal is: S<
dot dots dot   dash dash dash   dot dot dot>.
T
    
    is $x, q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>The emergency signal is: <br />dot&nbsp;dots&nbsp;dot&nbsp;&nbsp;&nbsp;dash&nbsp;dash&nbsp;dash&nbsp;&nbsp;&nbsp;dot&nbsp;dot&nbsp;dot.
</p></xhtml>#
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
=para
The emergency signal is: S<
dot dots dot   dash dash dash   dot dot dot>.
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><para /><para>The emergency signal is: <literallayout>
dot dots dot   dash dash dash   dot dot dot</literallayout>.
</para></chapter>#
    );
}

1;




