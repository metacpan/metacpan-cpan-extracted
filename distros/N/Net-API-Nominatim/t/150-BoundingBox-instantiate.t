#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '0.03';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use FindBin;
use Data::Roundtrip qw/perl2dump json2perl no-unicode-escape-permanently/;
use Test::TempDir::Tiny;
use File::Spec;

use Net::API::Nominatim::Model::BoundingBox;

my $VERBOSITY = 3;

#my $curdir = $FindBin::Bin;
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set

my ($bbox, $res);
my $I = {lat1 => 1.2, lon1 => 3.4, lat2 => 5.6, lon2 => 7.8};

# constructor from HASH
$bbox = Net::API::Nominatim::Model::BoundingBox->new($I);
ok(defined $bbox, "contructor called and returned good result.") or BAIL_OUT;
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox->$_();
	is($v, $I->{$_}, "field '$_' has the same value in bbox ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
}

# constructor from ARRAY
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  [ @$I{qw/lat1 lat2 lon1 lon2/} ]
);
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox->$_();
	is($v, $I->{$_}, "field '$_' has the same value in bbox ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
}
ok(defined $bbox, "contructor called and returned good result.") or BAIL_OUT;

# constructor from ARRAY of ARRAYS
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  [ [@$I{qw/lat1 lon1/}], [@$I{qw/lat2 lon2/}] ]
);
ok(defined $bbox, "contructor called and returned good result.") or BAIL_OUT;
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox->$_();
	is($v, $I->{$_}, "field '$_' has the same value in bbox ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
}

# constructor from another object of same class
my $bbox2 = Net::API::Nominatim::Model::BoundingBox->new($bbox);
ok(defined $bbox2, "contructor called and returned good result.") or BAIL_OUT;
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox2->$_();
	is($v, $I->{$_}, "field '$_' has the same value in bbox ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
}

my @ran = map { int(rand(28238721)) } 1..10;
for my $ran (@ran){
	srand $ran;
	# constructor from Random
	$bbox = Net::API::Nominatim::Model::BoundingBox::fromRandom();
	ok(defined $bbox, "contructor called and returned good result.") or BAIL_OUT;
	for(qw/lat1 lat2 lon1 lon2/){
		ok(defined($bbox->$_()), "field '$_' has defined value") or BAIL_OUT(perl2dump($bbox)."\nno see above bounding box with random coordinates.");
		ok(abs($bbox->$_()) > 1E-12, "field '$_' has non-zero value") or BAIL_OUT(perl2dump($bbox)."\nno see above bounding box with random coordinates.");
	}
}

# constructor from JSON String
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  "[ " . join(" , ", @$I{qw/lat1 lat2 lon1 lon2/}) . " ]"
);
ok(defined $bbox, "contructor called and returned good result.") or BAIL_OUT;
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox->$_();
	is($v, $I->{$_}, "field '$_' has the same value in bbox ($v) as in the input (".$I->{$_}.").") or BAIL_OUT;
}

# stringifiers: toString()
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  "[ " . join(" , ", @$I{qw/lat1 lat2 lon1 lon2/}) . " ]"
); # we need this exact bbox
my $str = $bbox->toString();
ok(defined $str, "toString(): called and got good result.") or BAIL_OUT;
my $exp = '[[1.2, 3.4],[5.6, 7.8]]';
is($str, $exp, "toString() : called and got exactly the result expected ($str).") or BAIL_OUT("no, it returned ($str) but expected ($exp).");
# parse it as JSON
my $p = json2perl($str);
ok(defined $p, "toString() : result validates as JSON.") or BAIL_OUT("${str}\nno, see above");
my $idx = 0;
for ('lat1', 'lon1', 'lat2', 'lon2'){
	my $i = int($idx / 2);
	my $j = $idx %2;
	my $ev = $bbox->$_();
	my $gv = $p->[$i]->[$j];
	is($gv, $ev, "toString() : parsed result as JSON and '$_' is what expected ($gv).") or BAIL_OUT(perl2dump($p)."no, it is ($gv) but expected ($ev), see above for all the JSON data returned from toString().");
	$idx++;
}

# stringifiers: toJSON()
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  "[ " . join(" , ", @$I{qw/lat1 lat2 lon1 lon2/}) . " ]"
); # we need this exact bbox
$str = $bbox->toJSON();
ok(defined $str, "toJSON(): called and got good result.") or BAIL_OUT;
$exp = '[1.2, 5.6, 3.4, 7.8]';
is($str, $exp, "toJSON() : called and got exactly the result expected ($str).") or BAIL_OUT("no, it returned ($str) but expected ($exp).");
# parse it as JSON
$p = json2perl($str);
ok(defined $p, "toJSON() : result validates as JSON.") or BAIL_OUT("${str}\nno, see above");
$idx = 0;
for ('lat1', 'lat2', 'lon1', 'lon2'){
	my $ev = $bbox->$_();
	my $gv = $p->[$idx];
	is($gv, $ev, "toJSON() : parsed result as JSON and '$_' is what expected ($gv).") or BAIL_OUT(perl2dump($p)."no, it is ($gv) but expected ($ev), see above for all the JSON data returned from toString().");
	$idx++;
}

# converter: toArray()
$bbox = Net::API::Nominatim::Model::BoundingBox->new(
  "[ " . join(" , ", @$I{qw/lat1 lat2 lon1 lon2/}) . " ]"
); # we need this exact bbox
my $arr = $bbox->toArray();
ok(defined $arr, "toJSON(): called and got good result.") or BAIL_OUT;
$exp = [ @$I{qw/lat1 lat2 lon1 lon2/} ];
is_deeply($arr, $exp, "toArraty() : called and got exactly the result expected ($arr).") or BAIL_OUT(perl2dump($arr)."\n".perl2dump($exp)."no, it returned above, 1.got, 2.expected.");

# equals
$bbox2 = Net::API::Nominatim::Model::BoundingBox->new($I);
ok(defined $bbox2, "contructor called and returned good result.") or BAIL_OUT;
is($bbox->equals($bbox2), 1, "equals() : new object is 'equal' to the source object.") or BAIL_OUT($bbox->toJSON()."\n".$bbox2->toJSON()."\nno, see above for the 1. source, 2. cloned.");
is($bbox2->equals($bbox), 1, "equals() : source object is 'equal' to the new object.") or BAIL_OUT($bbox->toJSON()."\n".$bbox2->toJSON()."\nno, see above for the 1. source, 2. cloned.");

# clone
$bbox2 = $bbox->clone;
ok(defined $bbox2, "clone() : called and got good result.") or BAIL_OUT;
is($bbox->equals($bbox2), 1, "clone() : cloned object is exactly the same as the source.") or BAIL_OUT($bbox->toJSON()."\n".$bbox2->toJSON()."\nno, see above for the 1. source, 2. cloned.");

# setters/getters
my $tv = 123.123;
for(qw/lat1 lat2 lon1 lon2/){
	my $v = $bbox->$_($tv);
	is($v, $tv, "testing setter $_".'()'." got value ($v) as expected.") or BAIL_OUT("no, got '$v' but expected '$tv'");
	$v = $bbox->$_();
	is($v, $tv, "testing getter $_".'()'." got value ($v) as expected.") or BAIL_OUT("no, got '$v' but expected '$tv'");
}

####### done ouph!

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
