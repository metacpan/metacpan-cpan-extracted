#===============================================================================
#
#  DESCRIPTION:  Test N<>
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::N;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use base 'TBase';

sub t01_as_xml : Test {
    my $t = shift;
    my $x = $t->parse_to_test( <<T);
=para
Text  this N<Some note>.
T
    is  $x->{CODE_N_COUNT}, 1, 'CODE_N_COUNT';
}

sub t02_as_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=begin pod
=para
Text  N<Same B<note>>.
=end pod
T

    $t->is_deeply_xml( $x,
q|<xhtml xmlns="http://www.w3.org/1999/xhtml"><p>Text  <sup><a name="nid1" href="#ftn.nid1">[1]</a></sup>.
</p><div class="footnote"><p>NOTES</p><p><a name="ftn.nid1" href="#nid1"><sup>1.</sup></a>Same <strong>note</strong></p></div></xhtml>|
    );
}

sub t03_as_bocbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T);
=begin pod
=para
Text  N<Same B<note>>.
=end pod
T
    $t->is_deeply_xml(
        $x,
q|<chapter><para>Text  <footnote><para>Same <emphasis role='bold'>note</emphasis></para></footnote>.
</para></chapter>|
    );
}

1;

