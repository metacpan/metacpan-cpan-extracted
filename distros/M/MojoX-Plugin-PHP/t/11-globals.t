use Test::More;
use Test::Mojo;
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

$t->app->hook( before_dispatch => sub {
    my $c = shift;
    while (my ($key,$val) = each %TestApp::Controller::Root::stash_globals) {
	$c->stash($key => $val);
    }
	       } );


{
    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = ();


    $t->get_ok('/globals.php')->status_is(200);
    my $content = $t->tx->res->body;

    ok( $content, 'content from globals.php available' );
    ok( $content =~ /g$_ not set/, "g$_ not set" ) for 1..5;




    %TestApp::Controller::Root::stash_globals = (
	g1 => 123,
	g2 => 456
	);


    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;

    ok( $content, 'response has content' );
    ok( $content =~ /g1=123/, 'g1 set in stash' );
    ok( $content =~ /g2=456/, 'g2 set in stash' );
    ok( $content =~ /g5 not set/, 'g5 not set' );


    %TestApp::Controller::Root::stash_globals = (
	g3 => "foo",
	g4 => [ 1, 3, 5 ]
	);

    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;

    ok( $content, 'response has content' );
    ok( $content =~ /g1 not set/, 'g1 set in stash' );
    ok( $content =~ /g3=foo/, 'g3 set in stash' );
    ok( $content =~ /g4=Array/, 'g4 set' );
    ok( $content =~ /g5 not set/, 'g5 not set' );



    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = (
	g2 => 17, g4 => "abcdefghj" );

    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;
    ok( $content =~ /g$_ not set/, "g$_ not set w/phptest_globals" ) for 1,3,5;
    ok( $content =~ /g2=17/, "g2 set w/phptest_globals" );
    ok( $content =~ /g4=abcdefghj/, "g4 set w/phptest_globals" );

    %TestApp::Controller::Root::stash_globals = (
	g1 => "abc", g2 => "def", g3 => "ghi" );
    %TestApp::View::PHPTest::phptest_globals = (
	g3 => "jkl", g4 => "mno", g5 => "pqr" );

    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;
    ok( $content =~ /g1=abc/ && $content =~ /g2=def/,
	"globals set with stash" );
    ok( $content =~ /g4=mno/ && $content =~ /g5=pqr/,
	"globals also set with phptest_globals" );
    ok( $content =~ /g3=jkl/,
	"g3 overwritten with phptest_globals" );
}

done_testing();
