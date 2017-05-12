# vim: et ts=8 sw=4 sts=4
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw ref_lost_memory ref_clear);
use Scalar::Util qw(refaddr);
use GrianUtils qw(ref_mem_safe total_sv loose $msg);
use strict;
use warnings;
no warnings 'once';
our $msg;

my @item ;
my $directory = qw(t/AMF0);
@item = GrianUtils->my_items($directory);

my $total = @item*2;
eval "use Test::More tests=>$total;";
warn $@ if $@;


TEST_LOOP:
for my $item (@item) {
    my ( $image_amf3, $image_amf0, $eval, $obj ) = @$item{qw(amf3 amf0 eval obj)};

    my $freeze = $image_amf0;
    my $a1     = $freeze . '0';
    my $a2     = $freeze;
    chop($a2);

    ok( !loose { my $a = thaw($a1); }, "thaw $item->{name} extra - $msg" );
    ok( !loose { my $a = thaw($a2); }, "thaw without one char $item->{name} - $msg" );
}
