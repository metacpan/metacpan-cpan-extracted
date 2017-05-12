#===============================================================================
#
#  DESCRIPTION:  test include block
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package T::Include;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';

sub p01_test_include_from_pod_with_patterns : Test {
    my $t = shift;
    my $x = $t->parse_to_test( <<T, );
=begin pod
=Include t/data/P_test1.pod
=end pod
T
    my $i1 = $x->{Include}->[0];
    is $i1->{PATH}, 't/data/P_test1.pod', '=Include t/data/P_test1.pod';
}

sub p02_test_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T, );
=begin pod
=Include t/data/P_test1.pod
=end pod
T
    $t->is_deeply_xml(
        $x,
        q#<xhtml xmlns="http://www.w3.org/1999/xhtml"><h1>Test
 </h1><h1>Test1 This is content
 </h1><h2>test level2
 </h2><p>para1
 </p><p>This is a secure hole !
 </p><h1>test
 </h1><p>This is a public gate..
 </p></xhtml>#
    );
}

sub p03_test_docbook : Test {
my $t = shift;
    my $x = $t->parse_to_docbook( <<T, );
=begin pod
=Include t/data/P_test1.pod
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<chapter><section><title>Test
</title></section><section><title>Test1 This is content
</title><section><title>test level2
</title><para>para1
</para><para>This is a secure hole !
</para></section></section><section><title>test
</title><para>This is a public gate..
</para></section></chapter>#
    );
}

sub p06_deep_include : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T, );
=begin pod
=Include t/data/unc_sub.pod
=end pod
T
    $t->is_deeply_xml(
        $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><p>Deep include
</p></xhtml>
#
      )
}


1;

