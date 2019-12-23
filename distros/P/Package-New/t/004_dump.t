# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;
use Devel::Hide qw(Data::Dumper);

BEGIN { use_ok( 'Package::New::Dump' ); }

my $object = Package::New::Dump->new(one=>{two=>{three=>{four=>{}}}});
isa_ok($object, 'Package::New::Dump');
isa_ok($object, 'Package::New');

my $value = $object->dump;
is($value, '', 'dump empty string');

my @value = $object->dump;
is(scalar(@value), 0, 'dump empty array');
