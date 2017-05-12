#===============================================================================
#
#  DESCRIPTION:  test L<> implementation
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::L;

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


sub a01_attrs:Test(3) {
    my $t = shift;
    my $x = $t->parse_to_test (<<T);
L<http://www.ru>
L<alter_text B<tet> | #section one >
T
    my ($l1, $l2 ,$l3 ) = @{ $x->{'L<>'}};
    is $l1->{address},'www.ru', 'address';
    is $l2->{address},'', 'empty address';
    is $l2->{'section'},'section one','#section one';
}


sub l001_syntax_Whitespace : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T);
=begin pod
test L<  http://perl.org  >
test L< haname | http:perl.html  >
=end pod
T
    $t->is_deeply_xml(
        $x,
q%<xhtml xmlns="http://www.w3.org/1999/xhtml"><p>test <a href="http://perl.org">http://perl.org</a>
test <a href="perl.html">haname</a>
</p></xhtml>%
    );
}

sub a05_http_scheme_to_xhtml : Test {
    my $t        = shift;
    my $x        = $t->parse_to_xhtml(<<TT);
=begin pod
=para
L<http://www.perl.org>
L< name |http://www.perl.org>
L< name |http://www.perl.org#Some>
=end pod
TT
    $t->is_deeply_xml(
        $x,
q%<xhtml xmlns='http://www.w3.org/1999/xhtml'><p><a href='http://www.perl.org'>www.perl.org</a>
<a href='http://www.perl.org'>name</a>
<a href='http://www.perl.org#Some'>name</a>
 </p></xhtml>%

    );
}


sub l12_link_with_name_docbook : Test {
    my $t  = shift;
    my $x = $t->parse_to_docbook( <<'T' );
=begin pod
=head1  test L<name|http://test> test
=end pod
T
    $t->is_deeply_xml( $x, q# <chapter><section><title>test <ulink url='http://test'>name</ulink> test
</title></section></chapter>#);
}

sub l13_link_only_addr_docbook : Test {
    my $t  = shift;
    my $x = $t->parse_to_docbook( <<'T');
=begin pod
=head1  test L<http://example.com> test
=end pod
T
    $t->is_deeply_xml( $x, q#<chapter><section><title>test <ulink url='http://example.com'>http://example.com</ulink> test
</title></section></chapter>#)
}


sub l14_tags_inside_text : Test {
    my $t  = shift;
    my $x = $t->parse_to_xhtml( <<'T');
=begin pod
=head1 test0 

L<B<test1>|http://example.com> test
L<I<Plain Ol' Documentation>|doc:perlpod>
=end pod
T
    $t->is_deeply_xml( $x,
   q#<xhtml xmlns="http://www.w3.org/1999/xhtml"><h1>test0 
</h1><p><a href="http://example.com"><strong>test1</strong></a> test
<a href="perlpod"><em>Plain Ol&apos; Documentation</em></a>
</p></xhtml>#)
}

sub l15_empty_text : Test {
    my $t  = shift;
    my $x = $t->parse_to_xhtml( <<'T');
=begin pod
L<http://example.com> test
=end pod
T
    $t->is_deeply_xml( $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p><a href='http://example.com'>http://example.com</a> test
</p></xhtml>#)
}
sub l16_mailto_xhtml : Test {
    my $t  = shift;
    my $x = $t->parse_to_xhtml( <<'T');
=begin pod
L<mailto:example.com> test
=end pod
T
$t->is_deeply_xml( $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p><a href='mailto:example.com'>mailto:example.com</a> test
</p></xhtml>
#)
}


1;
