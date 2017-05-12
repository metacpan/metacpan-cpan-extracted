# vim : ts=8 sw=4 sts=4
use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve parse_option);
use GrianUtils;
use constant MDATE=>parse_option( 'millisecond_date' );
use constant OPT_UD=>parse_option( 'utf8_decode, millisecond_date' );
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->my_items($directory);
my $total = @item*4;
#1) defined freeze
#2) defind  thaw freeze
#3) is_deeply thaw freeze
#4) is types are equal
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $packet (@item){
    my ($name, $image_amf3, $image_amf0, $eval, $obj) = @$packet{qw(name amf3 amf0 eval obj)};
	my $option = MDATE;
	$option = OPT_UD if ($eval =~m/use\s+utf8/) ;
	if ( $name =~m/boolean/ ){
#		print STDERR Dumper( $packet );
#		delete @$packet{ 'obj_xml', 'xml', 'dump', 'eval_xml', 'obj'};
#		$packet->{eval} = "''; ";
# GrianUtils->create_pack( '.', $name, $packet );
	    $eval =~s/JSON::XS::Boolean/JSON::PP::Boolean/g;
	}

	my $new_obj;
	ok(defined(Storable::AMF0::freeze($obj)), "defined ($name) $eval");
	ok(defined(Storable::AMF0::thaw(Storable::AMF0::freeze($obj)) xor not defined $obj), "full duplex $name");
	is_deeply($new_obj = Storable::AMF0::thaw($image_amf0, $option), $obj, "thaw name: ". $name. "(amf0):\n\n".$eval) 
		or diag( Data::Dumper->Dump([$new_obj, $obj, unpack("H*", $image_amf0)]));
	is(ref $new_obj, ref $obj, "type of: $name :: $eval");
}


