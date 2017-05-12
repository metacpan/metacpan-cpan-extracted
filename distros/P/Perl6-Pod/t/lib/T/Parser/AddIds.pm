#===============================================================================
#  DESCRIPTION: Test for make ids
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
package T::Parser::AddIds;
use Perl6::Pod::Parser::AddIds;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use base 'TBase';

sub i1_make_ids : Test {
    my $t = shift;
    my $x = $t->parse_to_xml( <<T, 'Perl6::Pod::Parser::AddIds' );
=begin pod
=head1 test
tst2
=end pod
T
    $t->is_deeply_xml(
        $x, q#
<pod pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><head1 pod:type='block' pod:id=':test_tst2'>test
tst2
</head1></pod>#
    );
}

sub i2_make_ids_with_base : Test {
    my $t       = shift;
    my $add_ids = new Perl6::Pod::Parser::AddIds:: ns => "namespace";
    my $x       = $t->parse_to_xml( <<T, $add_ids );
=begin pod
=head1 test
tst2
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<pod pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><head1 pod:type='block' pod:id='namespace:test_tst2'>test
tst2
</head1></pod>#
    );
}

1;
