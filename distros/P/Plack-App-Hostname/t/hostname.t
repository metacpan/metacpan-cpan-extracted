use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Plack::App::Hostname;
use Plack::Test;
use HTTP::Request::Common;

my $yippie = 'we will serve one and all';
my $yay_app = sub { [ 200, [], [ $yippie ] ] };
my $echo_app = sub { [ 200, [], [ $_[0]{'HTTP_HOST'} ] ] };
sub starry_app { my $patterns = "@_"; ( sub { [ 200, [], [ $patterns ] ] }, @_ ) }

my $map = Plack::App::Hostname->new
	->map_hosts_to( $echo_app, glob '{www.,}example.{com,net,org}' );

test_psgi app => $map, client => sub {
	my $cb = shift;

	# this smelly goop is necessary because Plack::Test and HTTP::Message::PSGI
	# both insist on helping us out by defaulting HTTP_HOST to localhost
	no warnings 'redefine';
	*HTTP::Request::to_psgi = sub {
		my $env = HTTP::Message::PSGI::req_to_psgi( @_ );
		delete $env->{'HTTP_HOST'} if 'localhost' eq $env->{'HTTP_HOST'};
		$env;
	};

	my $res;

	####################################################################

	$res = $cb->( GET 'http://example.com/' );
	ok $res->is_success, 'Request for mapped hostname succeeds...';

	for ( glob '{www.,}example.{com,net,org}' ) {
		$res = $cb->( GET "http://$_/" );
		is $res->content, $_, "... yep ($_)";
	}

	$res = $cb->( GET 'http://edit.example.com/' );
	is $res->code, 400, '... but unmapped hostname fails';

	####################################################################

	$map->map_hosts_to( $echo_app, 'edit.example.com' );

	$res = $cb->( GET 'http://edit.example.com/' );
	is $res->content, 'edit.example.com', 'Adding mappings later works';

	$map->unmap_host( 'edit.example.com' );

	$res = $cb->( GET 'http://edit.example.com/' );
	is $res->code, 400, '... and so does removing host mappings later';

	$res = $cb->( GET 'http://www.example.com/' );
	is $res->content, 'www.example.com', '... which only affects the unmapped host';

	$map->unmap_app( $echo_app );

	$res = $cb->( GET 'http://www.example.com/' );
	is $res->code, 400, '... unlike unmapping every instance of an app';

	####################################################################

	$map
		->map_hosts_to( starry_app '**.example.com' )
		->map_hosts_to( $echo_app, 'edit.example.com' );

	$res = $cb->( GET 'http://foo.bar.example.com/' );
	is $res->content, '**.example.com', 'Wildcards work ...';

	$res = $cb->( GET 'http://example.com/' );
	is $res->code, 400, '... and do not match the basename';

	$res = $cb->( GET 'http://edit.example.com/' );
	is $res->content, 'edit.example.com', '... nor overrule explicit matches';

	$map->map_hosts_to( starry_app '**.bar.example.com' );

	$res = $cb->( GET 'http://foo.bar.example.com/' );
	is $res->content, '**.bar.example.com', '... and match in specificity order';

	####################################################################

	$map->unmap_host( '**.example.com', '**.bar.example.com', 'edit.example.com' );

	$res = $cb->( GET 'http://example.com/' );
	is $res->code, 400, '(commercial break to clean the test slate)';

	####################################################################

	$map->default_app( $yay_app );

	$res = $cb->( GET 'http://example.com/' );
	is $res->content, $yippie, 'Unknown hosts can be caught...';

	$res = $cb->( GET '/' );
	is $res->code, 400, '... which is different from no Host: header at all';

	$map->default_app( undef );

	$res = $cb->( GET 'http://example.com/' );
	is $res->code, 400, '... and the fallback can be removed again';

	####################################################################

	$map->default_app( $yay_app );
	$map->missing_header_app( [ 301, [qw( Location http://www.dourish.com/goodies/see-figure-1.html )], [] ] );

	$res = $cb->( GET '/' );
	is $res->code, 301, 'A missing header can be handled...';

	$res = $cb->( GET 'http://whee.example.com/' );
	is $res->content, $yippie, '... which is different from an unknown host';

	$map->missing_header_app( undef );

	$res = $cb->( GET '/' );
	is $res->code, 400, '... and the handling can be removed again';
};

done_testing;
