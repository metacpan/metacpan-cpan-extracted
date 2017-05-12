#===============================================================================
#
#  DESCRIPTION:  Test placement link
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::FormattingCode::P;
use base 'TBase';
use strict;
use warnings;
use Data::Dumper;
use Test::More;

sub p01_test_include_from_pod_with_patterns : Test {
    return 1;
    my $t =shift;
    my $x = $t->parse_to_xml( <<T, );
=begin pod
=for para :allow<I>
wrwr
P<xref: t/data/P_test1.pod(head2 :public,head1 :private )>
=end pod
T
 $t->is_deeply_xml( $x, q#<pod pod:type='block' xmlns:pod='http://perlcabal.org/syn/S26.html'><para pod:type='block' allow='I'>wrwr
<P pod:section='' pod:type='code' pod:scheme='xref' pod:is_external='' pod:name='' pod:address='t/data/P_test1.pod(head2 :public,head1 :private )'><head1 pod:type='block' private='1'>Test1 This is content
</head1><head2 pod:type='block' public='1'>test level2
</head2></P>
</para></pod>#);
}

sub p02_test_include_from_pod_with_patterns_to_xml : Test {
    my $t =shift;
    my $x = $t->parse_to_xhtml( <<T, );
=begin pod
=head1 Main
=head2 main 
awaweqwe

P<file:t/data/P_test1.pod(para :private :public)>
=end pod
T
#        $t->parse_to_xhtml($pod),
    return 1;
}
1;


