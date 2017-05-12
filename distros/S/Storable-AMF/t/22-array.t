use lib 't';
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;

my $total;

my $obj = '[]: [1]: [1, "Favotite world!!!", 1.5]: ["Fav", 15, "Fav"]: do {$a = []; $$a[505] = 10; $a}:
	do {my @a = (1,2,4, undef); \@a} : do {my @a = (1,2,3,4); @a = 1; \@a}:
	do {my @a; @a= \@a; \@a}:
	do {my $a; @$a=($a, $a, 1, $a); $a} ';
$obj=~s/\s+$//;

my @item = split /:\s*/, $obj;

$total = 2*4*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $count =0 ;
(eval $_  ||  1) && $@ && die $@ foreach @item;
foreach (@item){
	my $image;
	my $obj = eval $_;
	my $new_obj;
	ok(defined($image = Storable::AMF3::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF3::thaw($image)), "defined thaw: $_");
 	is_deeply($new_obj, $obj, "primitive: $_");
 	is(unpack( "H*", Storable::AMF3::freeze($new_obj)), unpack( "H*", $image), "test image: $_");

	ok(defined($image = Storable::AMF0::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF0::thaw($image)), "defined thaw: $_");
 	is_deeply($new_obj, $obj, "primitive: $_");
 	is(unpack( "H*", Storable::AMF0::freeze($new_obj)), unpack( "H*", $image), "test image: $_");
	$count++;
}



