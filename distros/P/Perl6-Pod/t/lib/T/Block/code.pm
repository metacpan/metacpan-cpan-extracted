#===============================================================================
#
#  DESCRIPTION: test block =code
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$

package T::Block::code;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


sub c04_to_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T );
=begin pod
=code
    test code
=end pod
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><programlisting><![CDATA[    test code
 ]]></programlisting></chapter>#
    );
}

sub c05_allow_in_code : Test(2) {
    my $t = shift;
    my $x = $t->parse_to_xhtml(<<T);
=begin pod 
=for code :allow<B>
test B<para.test> para.test.I<pas>
=end pod
T
    ok $x =~ m{<strong>para.test</strong>}, ':allow<B>';
    ok $x =~ m{I&lt;pas&gt;}, 'deny format code';

}

sub c06_allow_in_latex_code : Test(2) {
    my $t = shift;
    my $x = $t->parse_to_latex(<<T);
=begin pod 
=for code :allow<B>
test B<para.test> para.test.I<pas>
=end pod
T
    ok $x =~ m%\\begin\{verbatim\}%, '=code in latex';
    ok $x =~ m%\\textbf\{para.%,':allow<B>';;
}
 
1;

