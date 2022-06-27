#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "weak_ref" => sub {
    mite_load <<'CODE';
package MyTest;
use Mite::Shim;
has foo =>
    is => 'rw',
    weak_ref => 1,
    writer => 1;
1;
CODE

    {
        my $arrayref = [];
        my $object = MyTest->new( foo => $arrayref );
        is_deeply( $object->foo, [], 'Constructor worked' );
        undef $arrayref;
        is_deeply( $object->foo, undef, '... and weakened properly' );
    }
    {
        my $object;
        my $arrayref = [];
        $object = MyTest->new();
        $object->set_foo( $arrayref );
        is_deeply( $object->foo, [], 'Writer worked' );
        undef $arrayref;
        is_deeply( $object->foo, undef, '... and weakened properly' );
    }
    {
        my $object;
        my $arrayref = [];
        $object = MyTest->new();
        $object->foo( $arrayref );
        is_deeply( $object->foo, [], 'Accessor worked' );
        undef $arrayref;
        is_deeply( $object->foo, undef, '... and weakened properly' );
    }
};

done_testing;
