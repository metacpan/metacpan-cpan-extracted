#! perl

use Test::MockTime qw//;
use Test::More;
use Test::Mojo;

use Mojolicious::Sessions::ThreeS::Storage::CHI;
use CHI;

my $oneday = 86400;

ok( my $storage = Mojolicious::Sessions::ThreeS::Storage::CHI->new({ chi => CHI->new( driver => 'Memory' , global => 0 ) }) );

$storage->store_session( 'noexpires' , { a => 1 , b => 2 } );
$storage->store_session( 'doexpires' , { c => 3 , d => 4 , expires => time() + $oneday } );
is_deeply( $storage->get_session('noexpires') , { a => 1 , b => 2 } );

{
    # Jump ahead in time (13 hours) and check the right session are still alive
    # This is the default behaviour
    Test::MockTime::set_relative_time( 46800 ); # This is 13 hours.
    ok( ! $storage->get_session('noexpires') , "Ok no session that expires in 12 hours by default");
    ok( $storage->get_session('doexpires') , "Ok got session that expires in one day");
    Test::MockTime::restore_time();
}

{
    # Jump ahead two days and check the one that expires is not there anymore.
    Test::MockTime::set_relative_time( 2 * $oneday );
    ok( ! $storage->get_session('doexpires') , "Session that lives only one day is gone");
    Test::MockTime::restore_time();
}

done_testing();

