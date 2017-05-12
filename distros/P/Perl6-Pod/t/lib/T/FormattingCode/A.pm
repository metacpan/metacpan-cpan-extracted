#===============================================================================
#
#  DESCRIPTION:  Test A
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::FormattingCode::A;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use base 'TBase';

sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=alias TEST B<Test1>
=para
Bold A<TEST>
T
    $t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Bold <strong>Test1</strong>
</p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=alias TEST B<Test1> 
=para
Bold A<TEST>
T
 $t->is_deeply_xml(
        $x,
q#<chapter><para>Bold <emphasis role='bold'>Test1</emphasis> 
</para></chapter>#)
}

sub t04_as_latex : Test {
    my $t = shift;
    my $x = $t->parse_to_latex( <<T);
=alias TEST B<Test1> 
=para
Bold A<TEST>
T
    ok $x =~ m%\\textbf\{Test1\}%, 'latex: A'
}

1;



