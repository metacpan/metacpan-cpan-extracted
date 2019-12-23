# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Package::New' ); }
BEGIN { use_ok( 'Package::New::Dump' ); }

my $obj1 = Package::New->new(x=>1, y=>"a");
isa_ok ($obj1, 'Package::New');

isa_ok($obj1->new, 'Package::New');

can_ok($obj1, qw{new initialize});
is($obj1->{"x"}, "1", "args work");
is($obj1->{"y"}, "a", "args work");

my $obj2 = Package::New::Dump->new(x=>2, y=>"b");
isa_ok($obj2, 'Package::New::Dump');
isa_ok($obj2, 'Package::New');
isa_ok($obj2->new, 'Package::New::Dump');

can_ok($obj2, qw{new initialize dump});
is($obj2->{"x"}, "2", "args work");
is($obj2->{"y"}, "b", "args work");
