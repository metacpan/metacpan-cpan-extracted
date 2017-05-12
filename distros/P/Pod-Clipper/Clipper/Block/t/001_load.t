# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 8;

BEGIN { use_ok( 'Pod::Clipper::Block' ); }

my $object = Pod::Clipper::Block->new({ data => "test data", is_pod => 0 });
isa_ok ($object, 'Pod::Clipper::Block');

is($object->data, "test data", "check the 'data' attribute value");
is($object->is_pod, 0, "check the 'is_pod' attribute value");

# set some new data
$object->data("new data");
$object->is_pod(1); # not really

is($object->data, "new data", "check the new 'data' attribute value");
is($object->is_pod, 1, "check the new 'is_pod' attribute value");

# will an object be created if we didn't pass the needed params?
eval { my $fail = Pod::Clipper::Block->new(); };
isnt($@, undef, "new() fails without the needed parameters");

eval {
    my $fail = Pod::Clipper::Block->new({ data => sub { }, is_pod => "Str" });
};
isnt($@, undef, "new() fails without the correct type of parameters");

# nothing much else to test here
