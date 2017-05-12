use lib 't';
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw retrieve parse_option);
use constant ODATE => parse_option('millisecond_date');
use GrianUtils ();

my $directory = qw(t/AMF3);
my @item  = GrianUtils->my_items( $directory );
my $total = @item * 2;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($name, $image_amf3, $obj, $dump) = @$item{qw(name amf3 obj dump)};
	my $new_obj;

	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3, ODATE), $obj, "thaw name: $name (amf3)") 
		or 0 && print STDERR Data::Dumper->Dump([$new_obj, $obj, unpack("H*", $image_amf3)]);
	is(ref $new_obj, ref $obj, "type of: $name ");
}


