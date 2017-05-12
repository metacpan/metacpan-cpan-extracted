use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;
use constant test_per_item=>2;
# vim: ts=8 et sw=4 sts=4

my $directory = qw(t/AMF0);
my @item ;
@item = grep $_->{name}=~m/^26-/, GrianUtils->my_items($directory);

my $total = @item*test_per_item;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($name, $obj, $image_amf3, $image_amf0, $eval) = @$item{qw(name obj amf3 amf0 eval)};
	my $new_obj;
	is_deeply(unpack("H*", Storable::AMF3::freeze($obj)), unpack( "H*",$image_amf3), "name: ". $name);
	is_deeply(unpack("H*", Storable::AMF0::freeze($obj)), unpack( "H*",$image_amf0), "name: ". $name);
}


