use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 ();
use GrianUtils;

# vim: ts=8 et sw=4 sts=4
my $directory = qw(t/AMF0);
my @item ;
@item = grep $_->{name}=~m/^25-/, GrianUtils->my_items($directory);

my $total = @item*1;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($image_amf3, $image_amf0, $eval) = @$item{qw(amf3 amf0 eval)};
	my $name = $item->{name};
	my $pob = $item->{obj};
	
	is_deeply(unpack("H*", Storable::AMF3::freeze( $pob)), unpack( "H*",$image_amf3), "name: ". $name);
}


