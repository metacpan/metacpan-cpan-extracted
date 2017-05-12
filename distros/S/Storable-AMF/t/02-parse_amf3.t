# vim: ts=8 et sw=4 sts=4
use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw retrieve parse_option);
use GrianUtils;
use constant MDATE=>parse_option( 'millisecond_date' );
use constant OPT_UD=>parse_option( 'utf8_decode, millisecond_date' );

my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->my_items($directory);

my $total = @item*4;
eval "use Test::More tests=>$total;";
warn $@ if $@;


TEST_LOOP: for my $packet (@item){
    my ($name, $image_amf3, $image_amf0, $obj, $eval) = @$packet{qw(name amf3 amf0  obj_xml eval_xml)};
	my $option = MDATE;
	$option = OPT_UD if ($eval =~m/use\s+utf8/) ;

	my $new_obj;
	ok(defined(Storable::AMF3::freeze($obj)), "defined ($name) $eval");
	ok(defined(Storable::AMF3::thaw(Storable::AMF3::freeze($obj)) xor not defined $obj), "full duplex $name");
	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3, $option), $obj, "thaw name: ". $name. "(amf3):\n\n") 
		or print STDERR Data::Dumper->Dump([$new_obj, $obj, unpack("H*", $image_amf3)]);
	is(ref $new_obj, ref $obj, "type of: $name :: $eval");
}
