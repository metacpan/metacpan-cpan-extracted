# vim: et ts=8 sw=4 sts=4
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw ref_lost_memory ref_clear);
use Scalar::Util qw(refaddr);
use lib 't';
use GrianUtils qw(ref_mem_safe $msg loose);
use strict;
use warnings;
no warnings 'once';

my @item ;
push @item, GrianUtils->my_items($_) for qw( t/AMF0 t/AMF3 );

my $total = @item*2;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP:
for my $item (@item) {
    my ( $name, $obj, $image_amf3, $image_amf0, $eval ) = @$item{qw(name obj amf3 amf0 eval)};

    my $freeze = $image_amf3;
    my $a1     = $freeze . '0';
    my $a2     = $freeze;
    chop($a2);

    ok( !loose { my $a = thaw($a1); }, "thaw $name extra - $msg" );
    ok( !loose { my $a = thaw($a2); }, "thaw without one char $name - $msg" );
}


