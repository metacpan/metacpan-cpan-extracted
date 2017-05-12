use strict;
use lib "t/lib";
use Test::More;
use Test::Exception;
use Orochi;

{
    my $c = Orochi->new();
    $c->inject_literal( foo => "123" );
    $c->inject( bar => $c->bind_value( ['baz', 'foo'] ) );

    is($c->get('foo'), 123);
    is($c->get('baz'), undef);
    is($c->get('bar' ), '123' );
}

{
    my $c = Orochi->new();
    $c->inject_class( 'Orochi::Test::MooseBased3' );
    $c->inject_literal( def => 100 );

    lives_and {
        isa_ok( $c->get( '/orochi/test/MooseBased3' ), 'Orochi::Test::MooseBased3' );
        is( $c->get('/orochi/test/MooseBased3')->baz, 100 );
    }
}

done_testing();