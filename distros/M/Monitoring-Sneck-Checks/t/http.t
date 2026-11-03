#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use LWP::UserAgent;
use Monitoring::Sneck::Checks;

# answers with whatever is set here instead of going to the network
my %answer;
my $sent;
{
	no warnings 'redefine';
	*LWP::UserAgent::request = sub {
		my ( $user_agent, $request ) = @_;
		$sent = { request => $request, user_agent => $user_agent };
		my $response = HTTP::Response->new( $answer{code} // 200, $answer{message} // 'OK' );
		$response->protocol('HTTP/1.1');
		$response->content_type( $answer{type} // 'text/html' );
		$response->content( $answer{content}   // '<html><body><p class="x">Welcome</p></body></html>' );
		$response->header( 'Client-Warning' => 'Internal response' ) if $answer{internal};
		$response->header( Location         => $answer{location} )   if defined( $answer{location} );
		return $response;
	}; ## end *LWP::UserAgent::request = sub
}
my $http = sub {
	my (@args) = @_;
	return Monitoring::Sneck::Checks->run( check => 'http', args => \@args );
};

my $return = $http->( '-H', 'www.example.org' );
is( $return->{code}, 0, '200 is OK' );
like( $return->{stdout},
	qr{\AHTTP OK - HTTP/1.1 200 OK - 50 bytes in [0-9.]+ seconds \| time=[0-9.]+s;;;0 size=50B;;;0\n\z}, 'output' );
is( $sent->{request}->uri,             'http://www.example.org/', 'URL' );
is( $sent->{request}->method,          'GET',                     'GET' );
is( $sent->{user_agent}->max_redirect, 0,                         'redirects not followed' );
is( $sent->{user_agent}->timeout,      29,                        'timeout' );

$http->( '-H', '2001:db8::10', '-S', '-p', 8443, '-u', 'status', '-f', '--insecure', '-k', 'X-Test: yes', '-P', 'a=1' );
is( $sent->{request}->uri,              'https://[2001:db8::10]:8443/status', 'HTTPS, IPv6, port, and path' );
is( $sent->{request}->method,           'POST',                               '--post makes it POST' );
is( $sent->{request}->content,          'a=1',                                'content sent' );
is( $sent->{request}->header('X-Test'), 'yes',                                'header sent' );
is( $sent->{user_agent}->max_redirect,  5,                                    '--follow' );
is( $sent->{user_agent}->ssl_opts('verify_hostname'), 0,                      '--insecure' );

$http->( '-u', 'https://api.example.org/health', '-j', 'head' );
is( $sent->{request}->uri,    'https://api.example.org/health', 'whole URL' );
is( $sent->{request}->method, 'HEAD',                           '--method' );

foreach my $status ( [ 301, 0 ], [ 404, 1 ], [ 503, 2 ] ) {
	local $answer{code} = $status->[0];
	is( $http->( '-H', 'www.example.org' )->{code}, $status->[1], 'status ' . $status->[0] );
}
{
	local $answer{code} = 404;
	is( $http->( '-H', 'www.example.org', '-e', '200,404' )->{code}, 0, '--expect' );
	local $answer{code} = 200;
	is( $http->( '-H', 'www.example.org', '-e', '204' )->{code}, 2, 'not --expect is CRITICAL' );
}
{
	local $answer{internal} = 1;
	local $answer{code}     = 500;
	local $answer{message}  = "Can't connect to www.example.org:80 (Connection refused)";
	$return = $http->( '-H', 'www.example.org' );
	is( $return->{code}, 2, 'not connecting is CRITICAL' );
	is( $return->{stdout},
		"HTTP CRITICAL - http://www.example.org/, Can't connect to www.example.org:80 (Connection refused)\n",
		'and why' );
}

# content
is( $http->( '-H', 'www.example.org', '-s', 'Welcome' )->{code}, 0, '--string found' );
$return = $http->( '-H', 'www.example.org', '-s', 'Goodbye' );
is( $return->{code}, 2, '--string missing' );
like( $return->{stdout}, qr/, did not find "Goodbye" \|/, 'and says so' );
is( $http->( '-H', 'www.example.org', '-r', 'W.lc' )->{code},                   0, '--regex' );
is( $http->( '-H', 'www.example.org', '-r', 'W.lc', '--invert-regex' )->{code}, 2, '--invert-regex' );
is( $http->( '-H', 'www.example.org', '-x', '//p[@class="x"]' )->{code},        0, '--xpath in HTML' );
is( $http->( '-H', 'www.example.org', '-x', '//table' )->{code},                2, '--xpath finding nothing' );
{
	local $answer{type}    = 'application/rss+xml';
	local $answer{content} = '<rss><channel><item>a</item></channel></rss>';
	is( $http->( '-H', 'www.example.org', '-x', '//item' )->{code}, 0, '--xpath in XML' );
}

# times
is( $http->( '-H', 'www.example.org', '-w', '@0:10' )->{code}, 1, 'slow is WARNING' );
like(
	$http->( '-H', 'www.example.org', '-c', '@0:10' )->{stdout},
	qr/HTTP CRITICAL - .*, slow \| time=[0-9.]+s;;\@0:10;0/,
	'slow is CRITICAL'
);

# location
{
	local $answer{code}     = 301;
	local $answer{location} = 'https://www.example.org/';
	is( $http->( '-H', 'www.example.org', '-L', 'https://www.example.org/' )->{code}, 0, '--location' );
	like(
		$http->( '-H', 'www.example.org', '-L', 'https://shop.example.org/' )->{stdout},
		qr/, redirects to https:\/\/www.example.org\/, not https:\/\/shop.example.org\/ \|/,
		'wrong --location'
	);
	local $answer{location} = '/login';
	is( $http->( '-H', 'www.example.org', '-S', '-L', 'https://www.example.org/login' )->{code},
		0, 'relative Location' );
	is( $http->( '-H', 'www.example.org', '-L', '/login' )->{code}, 0, 'relative --location' );
}
like(
	$http->( '-H', 'www.example.org', '-L', '/x' )->{stdout},
	qr/, no Location, wanted http:\/\/www.example.org\/x \|/,
	'no Location'
);
is( $http->( '-H', 'www.example.org', '-L', '/x', '-f' )->{code}, 3, '--location and --follow' );

# expect-header
{
	no warnings 'redefine';
	my $request = \&LWP::UserAgent::request;
	local *LWP::UserAgent::request = sub {
		my $response = $request->(@_);
		$response->header( 'Strict-Transport-Security' => 'max-age=63072000; includeSubDomains' );
		return $response;
	};
	is( $http->( '-H', 'www.example.org', '-E', 'strict-transport-security: max-age=[0-9]{8}' )->{code},
		0, '--expect-header' );
	like(
		$http->(
			'-H', 'www.example.org', '-E', 'Strict-Transport-Security: preload',
			'-E', 'Content-Security-Policy'
		)->{stdout},
		qr/, Strict-Transport-Security is "max-age=63072000; includeSubDomains", not matching \/preload\/, no Content-Security-Policy header \|/,
		'--expect-header not matching and not there'
	);
}
is( $http->( '-H', 'www.example.org', '-E', 'X: (' )->{code}, 3, 'bad --expect-header' );

# bad args
foreach my $bad (
	[],
	[ '-H', 'not a host' ],
	[ '-H', 'www.example.org', '-e', 'ok' ],
	[ '-H', 'www.example.org', '-r', '(' ],
	[ '-H', 'www.example.org', '-k', 'nope' ],
	[ '-H', 'www.example.org', '-w', 'x' ]
	)
{
	is( $http->( @{$bad} )->{code}, 3, 'bad args are UNKNOWN, ' . join( ' ', @{$bad} ) );
} ## end foreach my $bad ( [], [ '-H', 'not a host' ], [...])

done_testing();
