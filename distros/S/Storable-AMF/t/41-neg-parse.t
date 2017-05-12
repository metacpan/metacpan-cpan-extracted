use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;
my $directory = qw(t/AMF0);
# vim: ts=8 et sw=4 sts=4
my @item ;
@item = GrianUtils->my_items($directory);

my $total = @item*8;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($name, $obj, $image_amf3, $image_amf0, $eval) = @$item{qw(name obj amf3 amf0 eval)};

        my $freeze = freeze $obj;        
        my $a1 = $freeze;
        my $a2 = $freeze;
        chop($a1);
        $a2.='\x01';
        
        $@=undef;
		ok(! defined(thaw ($a1)), "fail of trunked ($name) $eval");
        ok($@, "has error for trunked".$eval);
        $@= undef;
		ok(! defined(thaw ($a2)), "fail of extra   ($name) $eval");
        ok($@, "has error for extra ".$eval);

        $@=undef;
		ok(! defined(Storable::AMF3::thaw ($a1)), "fail of trunked ($name) $eval");
        ok($@, "has error for trunked".$eval);
        $@= undef;
		ok(! defined(Storable::AMF3::thaw ($a2)), "fail of extra   ($name) $eval");
        ok($@, "has error for extra ".$eval);
}


