#===============================================================================
#
#  DESCRIPTION:  test B<> implementation
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$

package T::FormattingCode::I;
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
Italic I<test>
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Italic <em>test</em>
 </p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Italic I<test>
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><para>Italic <emphasis role='italic'>test</emphasis>
</para></chapter>#
    );
}

sub t03_as_latex : Test {
    my $t = shift;
    my $x = $t->parse_to_latex( <<T);
=para
Italic I<test>
T
ok $x =~ m%\\emph\{test\}%;
}

1;

