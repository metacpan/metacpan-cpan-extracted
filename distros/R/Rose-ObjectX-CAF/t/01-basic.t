use strict;
use Test::More tests => 7;
use_ok('Rose::ObjectX::CAF');

{

    package MyClass;
    @MyClass::ISA = ('Rose::ObjectX::CAF');
    MyClass->mk_accessors(qw(readwrite));
    MyClass->mk_ro_accessors(qw(readonly));
}

ok( my $obj = MyClass->new( readwrite => 1 ), "new object with hash" );
ok( my $obj2 = MyClass->new( { readonly => 1 } ),
    "new object with hash ref" );
ok( $obj->readwrite, "has readwrite method" );
eval { $obj2->readonly('foo'); };
ok( $@,                   "cannot set readonly method" );
ok( $obj->readwrite(123), "set readwrite method" );
is( $obj->readwrite, 123, "set worked" );
