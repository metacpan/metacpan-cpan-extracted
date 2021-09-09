#! perl

use Test::Lib;
use Test2::V0;

use PDL::Lite ();

use My::Class;

sub new {
    My::Class::Single()->new(
        p1 => PDL->sequence( 5 ),
        p2 => PDL->sequence( 5 ),
    );
}

subtest basic => sub {
    my $obj = new();

    is( !!$obj->is_inplace, !!0,  "initialized: not inplace" );
    is( $obj->inplace,      $obj, "inplace returns object" );
    is( !!$obj->is_inplace, !!1,  "inplace sets flag" );
    $obj->set_inplace( 0 );
    is( !!$obj->is_inplace, !!0, "set_inplace resets flag" );
    $obj->set_inplace( 1 );
    is( !!$obj->is_inplace, !!1, "set_inplace sets flag" );
};

subtest 'test trigger' => sub {

    my $obj = new();

    is( !!$obj->triggered, !!0, "trigger cleared" );
    $obj->_set_p1( PDL->ones( 20 ) );
    is( !!$obj->triggered, !!1, "accessor trigger works" );
};

subtest 'accessor' => sub {
    my $obj = new();

    is( !!$obj->triggered, !!0, "trigger cleared" );
    $obj->inplace->where( PDL->new( 1 ) );
    is( !!$obj->triggered, !!1, "triggered" );
};


subtest 'store' => sub {
    my $obj = new();

    is( !!$obj->triggered, !!0, "trigger cleared" );
    $obj->inplace_store->where( $obj->p1 > 2 );
    is( !!$obj->triggered, !!0, "not triggered" );
};

done_testing;
