#===============================================================================
#
#  DESCRIPTION:   test T<>
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::FormattingCode::T;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';

sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=para
Got C<uname> output : T<FreeBSD>
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Got <code>uname</code> output : <samp>FreeBSD</samp>
</p></xhtml>#
    );
}

sub t03_as_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=para
Got C<uname> output : T<FreeBSD>
T
    $t->is_deeply_xml(
        $x,
        q#<chapter><para>Got <code>uname</code> output : <computeroutput>FreeBSD</computeroutput>
</para></chapter>#
    );
}

1;





