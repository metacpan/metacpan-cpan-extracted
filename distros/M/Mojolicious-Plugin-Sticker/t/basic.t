use Test::More;
use Test::Mojo;
use Mojo::File;

my $t = Test::Mojo->new( Mojo::File->new('t/lib/apps/main') );

$t->get_ok('/foo')->status_is(200)
  ->json_is( '/foo', 123, 'first route from app "foo"' );

$t->get_ok('/bar')->status_is(200)
  ->json_is( '/bar', 456, 'first route from app "bar"' );

$t->post_ok( '/baz', {}, json => { baz => 13 } )->status_is(200)
  ->json_is( '/baz', 55, 'second route from app "bar"' );

done_testing();

