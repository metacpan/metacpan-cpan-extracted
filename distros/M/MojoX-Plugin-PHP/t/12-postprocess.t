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

    $t->get_ok( '/globals.php' )->status_is(200);
    my $content = $t->tx->res->body;
    ok( $content, 'content from globals.php available' );
    ok( $content =~ /g$_ not set/, "g$_ not set" ) for 1..5;




    %TestApp::Controller::Root::stash_globals = (
	g1 => 123,
	g2 => 456
	);

    $t::MojoTestServer::postprocessor = sub {
	my ($output, $headers, $c) = @_;
	$$output =~ s/5/7/g;
    };

    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;

    ok( $content, 'response has content' );
    ok( $content =~ /g1=123/, 'g1 set in stash' );
    ok( $content =~ /g2=476/, 'g2 set in stash, output postprocessed' );
    ok( $content =~ /g7 not set/, 'g5 not set, output postprocesed' );


    %TestApp::Controller::Root::stash_globals = (
	g3 => "foo",
	g4 => [ 1, 3, 5 ]
	);

    $t::MojoTestServer::postprocessor = sub {
	my ($output, $headers, $c) = @_;
	$$output = "this content has been deleted";
    };

    $t->get_ok('/globals.php')->status_is(200)
	->content_like( qr/./ )
	->content_is( 'this content has been deleted' );

    %TestApp::Controller::Root::stash_globals = ();
    %TestApp::View::PHPTest::phptest_globals = (
	g2 => 17, g4 => "abcdefghj" );

    $t::MojoTestServer::postprocessor = sub {
	my $output = shift;
	my $g4 = reverse PHP::eval_return('$g4');
	$$output .= "<pre>\nreverse G4 is $g4\n</pre>\n";
    };

    $t->get_ok('/globals.php')->status_is(200);
    $content = $t->tx->res->body;

    ok( $content, 'response has content' );
    ok( $content =~ /reverse G4 is jhgfedcba/,
	'output postprocessor has access to PHP interpreter' );
}

done_testing();
