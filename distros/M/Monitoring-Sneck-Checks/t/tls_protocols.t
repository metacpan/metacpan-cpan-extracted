#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use IO::Socket::SSL;
use TestCerts;
use TestServer;
use Monitoring::Sneck::Checks;

plan( skip_all => 'needs fork' ) if $^O eq 'MSWin32';

my $dir   = TestTmp::dir();
my $paths = TestCerts::make( $dir, { name => 'www', days => 90, names => [ 'www.example.org', '127.0.0.1' ] } );
my %cert  = ( SSL_cert_file => $paths->{www} . '.pem', SSL_key_file => $paths->{www} . '.key' );

# one server taking only TLS 1.2 and 1.3, one taking 1.0 to 1.3, if this OpenSSL can at all
my ( $modern_port, $modern_pid )
	= TestServer::start( ssl => { %cert, SSL_version => 'SSLv23:!SSLv3:!TLSv1:!TLSv1_1' } );
my ( $old_port, $old_pid )
	= TestServer::start( ssl => { %cert, SSL_version => 'SSLv23:!SSLv3', SSL_cipher_list => 'ALL:@SECLEVEL=0' } );
my $parent = $$;
END { kill( 'TERM', $modern_pid, $old_pid ) if $$ == $parent }
my $run = sub {
	return Monitoring::Sneck::Checks->run(
		check   => 'tls_protocols',
		args    => [ '-H', '127.0.0.1', @_ ],
		timeout => 5
	);
};

my $return = $run->( '-p', $modern_port, '-a', 'TLSv1_2', '-a', 'TLSv1_3', '-r', 'TLSv1', '-r', 'TLSv1_1' );
is( $return->{code}, 0, 'modern server' );
is( $return->{stdout}, "TLS_PROTOCOLS OK - 127.0.0.1:$modern_port takes TLSv1.2, TLSv1.3, refuses TLSv1.0, TLSv1.1\n",
	'output' );
is( $run->( '-p', $modern_port )->{code}, 0, 'refusing 1.0 and 1.1 by default' );

SKIP: {
	my $can_old = $run->( '-p', $old_port, '-a', 'TLSv1' );
	skip( 'this OpenSSL can not do TLS 1.0', 2 ) if $can_old->{code} == 3;
	is( $can_old->{code}, 0, 'old server takes TLS 1.0' );
	is(
		$run->( '-p', $old_port )->{stdout},
		"TLS_PROTOCOLS CRITICAL - 127.0.0.1:$old_port takes TLSv1.0, TLSv1.1, should refuse TLSv1.0, TLSv1.1\n",
		'taking old versions is CRITICAL'
	);
} ## end SKIP:
like(
	$run->( '-p', $modern_port, '-a', 'TLSv1_1' )->{stdout},
	qr/\ATLS_PROTOCOLS CRITICAL - \S+ refuses TLSv1.1, should take TLSv1.1\n\z/,
	'--accept not taken'
);
like(
	$run->( '-p', $modern_port, '-r', 'SSLv3' )->{stdout},
	qr/(?:refuses SSLv3|could not try SSLv3)/,
	'SSLv3 refused or not able to be tried'
);
my $closed = do {
	my $socket = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1 );
	my $port   = $socket->sockport;
	close($socket);
	$port;
};
like(
	$run->( '-p', $closed )->{stdout},
	qr/\ATLS_PROTOCOLS UNKNOWN - 127.0.0.1:$closed could not try TLSv1.0, can not connect/,
	'not connecting'
);
is( $run->( '-r', 'TLSv9' )->{code},  3, 'bad version' );
is( $run->( '-s', 'gopher' )->{code}, 3, 'bad --starttls' );

done_testing();
