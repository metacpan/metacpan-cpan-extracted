use Test::More;
use Test::Mojo;
use strict;
use warnings;
use Mojo::Util qw(decode);

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

use utf8;

{
    $t->get_ok( '/hello_utf8.php' )->status_is(200);
    my $content = $t->tx->res->body;
    my $content2 = decode("utf-8", $content);
    ok($content ne $content2, 'PHP output contains wide chars' );
    $t->content_is( "Xin chào thế giới" );
}

{
    $t->get_ok( "/hello_latin1.php" )->status_is(200);
    my $content = $t->tx->res->body;
    my $content2 = decode("iso-8859-1", $content);
    $t->content_is( "Héllo Wörld" );
}

done_testing();
