use strict; use warnings;

use Test::FailWarnings;
use Test::More 1.001002; # new enough for sanity in done_testing()

use POE 1.267;
use POE::Component::Client::TCP;
use POE::Component::TLSify qw/Client_TLSify Server_TLSify TLSify_GetSocket TLSify_GetCipher/;

our $GOT_FILTER;

BEGIN {
    eval {
        require POE::Filter::HTTP::Parser;
        $GOT_FILTER = 1;
    };
}

if (!$GOT_FILTER) {
    plan skip_all => "POE::Filter::HTTP::Parser not available";
}

plan 'no_plan';

POE::Component::Client::TCP->new
(
	Alias		=> 'myclient',
	RemoteAddress	=> 'www.google.com',
	RemotePort	=> '443',
  Filter  => POE::Filter::HTTP::Parser->new( type => 'client' ),

	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');
    require HTTP::Request;
    my $req = HTTP::Request->new( GET => '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'Host', 'www.google.com:443' );
    $req->user_agent( sprintf( 'POE-Component-TLSify/%s (perl; N; POE; en; rv:%f)', '99.99', $POE::VERSION ) );
		$_[HEAP]->{server}->put($req);
	},
	PreConnect	=> sub
	{
		my $socket = eval { Client_TLSify($_[ARG0]) };
		ok(!$@, "CLIENT: Client_TLSify $@");
		ok(1, 'CLIENT: TLSify_GetCipher: '. TLSify_GetCipher($socket));

		# We pray that IO::Handle is sane...
		ok( TLSify_GetSocket( $socket )->blocking == 0, 'CLIENT: SSLified socket is non-blocking?') if $^O ne 'MSWin32';

		return ($socket);
	},
	ServerInput	=> sub
	{
		my ($kernel, $heap, $resp) = @_[KERNEL, HEAP, ARG0];

		if ($resp->code == 200) {
			ok(1, "CLIENT: recv: " . $resp->code);

			## At this point, connection MUST be encrypted.
			my $cipher = TLSify_GetCipher($heap->{server}->get_output_handle);
			ok($cipher ne '(NONE)', "CLIENT: TLSify_GetCipher: $cipher");
			diag( TLSify_GetSocket( $heap->{server}->get_output_handle )->dump_peer_certificate() ) if $ENV{TEST_VERBOSE};

			$kernel->yield('shutdown');
		} else {
			die "Unknown line from SERVER";
		}
	},
	ServerError	=> sub
	{
		# Thanks to H. Merijn Brand for spotting this FAIL in 5.12.0!
		# The default PoCo::Client::TCP handler will throw a warning, which causes Test::NoWarnings to FAIL :(
		my ($syscall, $errno, $error) = @_[ ARG0..ARG2 ];

		# TODO are there other "errors" that is harmless?
		$error = "Normal disconnection" unless $error;
		my $msg = "Got CLIENT $syscall error $errno: $error";
		unless ( $syscall eq 'read' and $errno == 0 ) {
			fail( $msg );
		} else {
			diag( $msg ) if $ENV{TEST_VERBOSE};
		}
	},
);

$poe_kernel->run();

done_testing;
