use Test::More;
use Test::Mojo;
use Data::Dumper;
use strict;
use warnings;

$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is('This is t::MojoTestServer');


{
    my $input = q{This is some content.
There is a lot of content like it.
This content is mine.};

    $t->post_ok('/body', $input )->status_is(200, '/body call');
    my $content = $t->tx->res->body;

    ok( $content eq Data::Dumper::Dumper($input),
	"received raw input back" );

    $t->post_ok('/body.php', $input)->status_is(200, '/body.php call');
    $content = $t->tx->res->body;

    ok( $content eq $input, 
	"received raw input back from \$HTTP_RAW_POST_DATA" );

    $t->post_ok('/body2.php', $input)->status_is(200, '/body2.php call');
    $content = $t->tx->res->body;
    ok( $content eq $input, "received raw input back from php://input" );
}

done_testing();
