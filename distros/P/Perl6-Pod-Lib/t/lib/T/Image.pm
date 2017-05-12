#===============================================================================
#
#  DESCRIPTION: test Image block
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package T::Image;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::Lib::Include;
use base 'TBase';

sub p01_test_Image : Test(4) {
    my $t = shift;
    my $x = $t->parse_to_test( <<T, );
=begin pod
=Image Title | t/data/P_test1.jpg
=for Image :title('Test title')
t/data/P_test1.jpg

=end pod
T
    my $i1 = $x->{Image}->[0];
    is $i1->{SRC}, 't/data/P_test1.jpg', 'image src';
    is $i1->{TITLE}, 'Title', 'check title';
    my $i2 = $x->{Image}->[0];
    is $i2->{SRC}, 't/data/P_test1.jpg', 'image src';
    is $i2->{TITLE}, 'Title', 'check title';
}

sub p02_test_xhtml : Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml( <<T, );
=begin pod
=Image Test caption|http://t/data/P_test1.jpg
=end pod
T
    $t->is_deeply_xml( $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><img alt='Test caption' src='http://t/data/P_test1.jpg' title='Test caption' /></xhtml>#
    );
}

sub p03_test_docbook : Test {
    my $t = shift;
    my $x = $t->parse_to_docbook( <<T, );
=begin pod
=for Image :title('test')
t/data/P_test1.png
=end pod
T
    $t->is_deeply_xml( $x,
q#<chapter><mediaobject><imageobject><imagedata align='center' caption='test' format='PNG' valign='bottom' scalefit='1' fileref='t/data/P_test1.png' /></imageobject><caption>test</caption></mediaobject></chapter>#
    );
}

sub p04_deep_include : Test(2) {
    my $t = shift;
    my $pod = <<T;
=begin pod
=Include t/data/inc_sub_imgage.pod
=end pod
T
    my $x = $t->parse_to_xhtml( $pod );
    $t->is_deeply_xml( $x,
q#<xhtml xmlns='http://www.w3.org/1999/xhtml'><img alt='' src='t/data/subdir/test1.png' title='' /></xhtml>#,'include xhtml'
    );
    my $xd = $t->parse_to_docbook( $pod );
    $t->is_deeply_xml( $xd,
q#<chapter><mediaobject><imageobject><imagedata align='center' caption='' format='PNG' valign='bottom' scalefit='1' fileref='t/data/subdir/test1.png' /></imageobject><caption /></mediaobject></chapter>#,'include docbook'
    );
}

1;

