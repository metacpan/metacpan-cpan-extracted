#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use LWP::UserAgent;
use Monitoring::Sneck::Checks;

my $content
	= '{"status":"ok","healthy":true,"down":null,"queue":{"depth":120},"nodes":[{"name":"a"},{"name":"b"}],"count":"x"}';
{
	no warnings 'redefine';
	*LWP::UserAgent::request = sub {
		my $response = HTTP::Response->new( 200, 'OK' );
		$response->protocol('HTTP/1.1');
		$response->content_type('application/json');
		$response->content($content);
		return $response;
	};
}
my $json = sub {
	return Monitoring::Sneck::Checks->run(
		check => 'http_json',
		args  => [ '-u', 'https://api.example.org/health', @_ ]
	);
};

my $return = $json->(
	'-J', 'status=ok',      '-J', 'healthy=true',    '-J', 'down=null',
	'-J', 'nodes.1.name=b', '-J', 'nodes.-1.name=b', '-J', 'queue'
);
is( $return->{code}, 0, 'values there' ) || diag( $return->{combined} );
like( $return->{stdout}, qr{\AHTTP_JSON OK - HTTP/1.1 200 OK - \d+ bytes in [0-9.]+ seconds \| time=}, 'output' );
$return = $json->( '-J', 'status=down', '-J', 'nodes.2.name', '-J', 'queue=1', '-J', 'missing' );
is( $return->{code}, 2, 'wrong values are CRITICAL' );
like( $return->{stdout},
	qr/, status is ok, not down, nodes.2.name is not there, queue is a object, not 1, missing is not there \|/,
	'each said' );

$return = $json->( '-V', 'queue.depth', '-W', 100, '-C', 500 );
is( $return->{code}, 1, '--value over warning' );
like( $return->{stdout}, qr/, queue.depth is 120 \| queue.depth=120;100;500 time=/, 'and in perfdata' );
is( $json->( '-V', 'queue.depth', '-C', 1000 )->{code}, 0, '--value OK' );
like( $json->( '-V', 'count' )->{stdout}, qr/count is x, not a number/,        'not a number' );
like( $json->( '-V', 'nope' )->{stdout},  qr/nope is not there, not a number/, 'not there' );
is( $json->( '-J', 'status=ok', '-s', 'nodes' )->{code}, 0, 'http options still work' );
{
	my $saved = $content;
	$content = '<html>not json</html>';
	like( $json->( '-J', 'status' )->{stdout}, qr/\AHTTP_JSON CRITICAL - .*, content is not JSON/, 'not JSON' );
	$content = $saved;
}
is( $json->()->{code},                     3, 'nothing to check' );
is( $json->( '-W', 1, '-J', 'a' )->{code}, 3, '--value-warning without --value' );

done_testing();
