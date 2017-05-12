use lib 't';
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 ();
use GrianUtils;

my $total;

my $obj = '1, 2, 3, -4, 1.5, 2.0, 4.0 , -4.25';
my @item = split /,\s*/, $obj;

$total = 2*4*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;

foreach (@item){
	my $image;
	my $obj = eval $_;
	my $new_obj;

	ok(defined($image   = Storable::AMF3::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF3::thaw($image)), "defined thaw: $_");

	is($new_obj, $obj, "primitive: $_");
	is(unpack( "H*", Storable::AMF3::freeze($new_obj)), unpack( "H*", $image), "test image: $_");

	ok(defined($image = Storable::AMF0::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF0::thaw($image)), "defined thaw: $_");

	is($new_obj, $obj, "primitive: $_");
	is(unpack( "H*", Storable::AMF0::freeze($new_obj)), unpack( "H*", $image), "test image: $_");
}



