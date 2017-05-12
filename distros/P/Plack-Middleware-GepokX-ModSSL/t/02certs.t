use Test::More;

BEGIN {
	unless ($ENV{RELEASE_TESTING}) {
		plan skip_all => 'these tests are for release candidate testing'
	}
}

use Gepok;
use Net::SSL;
use Net::SSLeay;
use Plack::Middleware::GepokX::ModSSL;

-d './t/certs/'
	or die "./t/certs/ doesn't exist... are you running this from the right place?\n";

my $port = int(rand(30_000) + 2048);
$ENV{HTTPS_CERT_FILE} = 't/certs/client-crt.pem';
$ENV{HTTPS_KEY_FILE}  = 't/certs/client-key-nopass.pem';

plan tests => 1;

# Performs HTTPS GET request. I wasn't able to pursuade LWP::UserAgent
# to reliably use X509 certificates.
sub get
{
	my $path = shift;
	my $sock = Net::SSL->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $port,
		Timeout => 15,
		);
	$sock || ($@ ||= "no Net::SSL connection established");
	my $error = $@;
	$error && die("Can't connect to $host:$port; $error; $!");
	
	$sock->print("GET $path HTTP/1.0\r\n");
	$sock->print("Host: 127.0.0.1\r\n");
	$sock->print("\r\n");
	
	my $out = '';
	my $buf = '';
	while ($sock->read($buf, 1024))
	{
		$out .= $buf;
	}
	
	return $out;
}

# PEM certificate canonicaliser.
sub parsed
{
	my @lines      = split /\r?\n|\r/, shift;
	
	my ($start, $finish) = (0, 0);
	my @cert_lines = grep {
		$start++  if /BEGIN CERTIFICATE/;
		$finish++ if /END CERTIFICATE/;
		$start && !$finish;
	} @lines;
	shift @cert_lines;
	
	join '', @cert_lines;
}

if (my $child = fork)
{
	sleep 1;
	my $got_cert      = get('/test');
	my $expected_cert = do { local(@ARGV, $/) = $ENV{HTTPS_CERT_FILE}; <> };
	
	is(parsed($got_cert), parsed($expected_cert));
	kill 9, $child; # a bit harsh, I know
	exit(0);
}
else
{
	my $daemon;
	my $app  = sub
	{
		my $env = shift;
		
		return [
			200,
			[ 'Content-Type' => 'text/plain' ],
			[ $env->{'SSL_CLIENT_CERT'} ],
		]
	};
	
	$daemon = Gepok->new(
		https_ports         => [$port],
		ssl_key_file        => 't/certs/server-key-nopass.pem',
		ssl_cert_file       => 't/certs/server-crt.pem',
		ssl_verify_mode     => 0x01,
		ssl_verify_callback => '1',
		ssl_ca_path         => '/etc/pki/tls/rootcerts/',
		daemonize           => 0,
	);
	$daemon->run(
		Plack::Middleware::GepokX::ModSSL->wrap(
			$app,
			vars => [ Plack::Middleware::GepokX::ModSSL->all ]
		)
	);
}

