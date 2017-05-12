use strict;
use lib "t/lib";
use Test::More;
use Orochi;

{
    my $c = Orochi->new();
    $c->inject_literal( '/orochi/test/MooseBased1/foo', 1 );
    $c->inject_literal( '/orochi/test/MooseBased1/bar', 2 );
    $c->inject_class( 'Orochi::Test::MooseBased1' );

    my $o = $c->get( '/orochi/test/MooseBased1' );
    ok($o);
    isa_ok($o, 'Orochi::Test::MooseBased1' );
    is( $o->foo, 1 );
    is( $o->bar, 2 );
}

{
    my $c = Orochi->new();
    $c->inject_literal( '/orochi/test/MooseBased1/foo', 1 );
    $c->inject_literal( '/orochi/test/MooseBased1/bar', 2 );
    $c->inject_class( 'Orochi::Test::MooseBased1' );
    $c->inject_class( 'Orochi::Test::MooseBased2' );

    my $o = $c->get( '/orochi/test/MooseBased2' );
    ok($o);
    isa_ok($o, 'Orochi::Test::MooseBased2' );
    isa_ok( $o->foo, 'Orochi::Test::MooseBased1' );
    is( $o->foo->foo, 1 );
    is( $o->foo->bar, 2 );
}

done_testing;