#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use TestCerts;
use TestServer;
use IO::Socket::SSL;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::https_cert;

plan( skip_all => 'needs fork' ) if $^O eq 'MSWin32';

my $dir   = TestTmp::dir();
my $paths = TestCerts::make( $dir, { name => 'www', days => 20, names => [ 'www.example.org', '127.0.0.1' ] } );
my @pids;
my $parent_pid = $$;
END { kill( 'TERM', @pids ) if @pids && $$ == $parent_pid }

my ( $plain_port, $plain_pid )
	= TestServer::start( greeting => "220 test ready\r\n", answers => { PING => "+PONG\r\n" } );
my %cert = ( SSL_cert_file => $paths->{www} . '.pem', SSL_key_file => $paths->{www} . '.key' );
my ( $tls_port,   $tls_pid )   = TestServer::start( greeting => "* OK ready\r\n", ssl => \%cert );
my ( $smtps_port, $smtps_pid ) = TestServer::start(
	greeting => "220 mail.example.org ESMTP\r\n",
	answers  => { 'EHLO client.example.org' => "250-mail.example.org\r\n250 8BITMIME\r\n" },
	ssl      => \%cert
);
push( @pids, $plain_pid, $tls_pid, $smtps_pid );

# STARTTLS servers, each answering as the protocol does, then going TLS, and talking SMTP over it
# for the smtp check, the others closing once they have the certificate
my %server_ssl = ( SSL_server => 1, %cert );
my $upgrade    = sub {
	my ($client) = @_;
	IO::Socket::SSL->start_SSL( $client, %server_ssl ) or return;
	while ( my $line = <$client> ) {
		last                                                     if $line =~ /\AQUIT/;
		print $client "250-mail.example.org\r\n250 8BITMIME\r\n" if $line =~ /\AEHLO /;
	}
};
my %starttls = (
	smtp => sub {
		my ($client) = @_;
		print $client "220-mail.example.org ESMTP\r\n220 ready\r\n";
		<$client> =~ /^EHLO / or return;
		print $client "250-mail.example.org\r\n250-PIPELINING\r\n250-STARTTLS\r\n250 8BITMIME\r\n";
		<$client> eq "STARTTLS\r\n" or return;
		print $client "220 go ahead\r\n";
		$upgrade->($client);
	},
	smtp_no_tls => sub {
		my ($client) = @_;
		print $client "220 ready\r\n";
		<$client>;
		print $client "250-mail.example.org\r\n250 8BITMIME\r\n";
	},
	smtp_helo => sub {
		my ($client) = @_;
		print $client "220 ready\r\n";
		<$client> eq "EHLO client.example.org\r\n" or return;
		print $client "250-mail.example.org\r\n250 STARTTLS\r\n";
		<$client> eq "STARTTLS\r\n" or return;
		print $client "220 go ahead\r\n";
		$upgrade->($client);
	},
	imap => sub {
		my ($client) = @_;
		print $client "* OK IMAP4rev1 ready\r\n";
		<$client> eq "a1 STARTTLS\r\n" or return;
		print $client "* note\r\na1 OK begin TLS\r\n";
		$upgrade->($client);
	},
	pop3 => sub {
		my ($client) = @_;
		print $client "+OK POP3 ready\r\n";
		<$client> eq "STLS\r\n" or return;
		print $client "+OK begin TLS\r\n";
		$upgrade->($client);
	},
	ftp => sub {
		my ($client) = @_;
		print $client "220 FTP ready\r\n";
		<$client> eq "AUTH TLS\r\n" or return;
		print $client "234 AUTH TLS ok\r\n";
		$upgrade->($client);
	},
	ldap => sub {
		my ($client) = @_;
		sysread( $client, my $request, 100 );
		return if $request ne $Monitoring::Sneck::Checks::https_cert::LDAP_STARTTLS;
		print $client pack( 'H*', '300c02010178070a010004000400' );
		$upgrade->($client);
	},
	ldap_refused => sub {
		my ($client) = @_;
		sysread( $client, my $request, 100 );
		print $client pack( 'H*', '300c02010178070a013404000400' );
	},
);
my %starttls_ports;
foreach my $protocol ( sort( keys(%starttls) ) ) {
	my ( $port, $pid ) = TestServer::start( handler => $starttls{$protocol} );
	$starttls_ports{$protocol} = $port;
	push( @pids, $pid );
}

# a port nothing is on
my $closed_port = do {
	my $socket = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1 );
	my $port   = $socket->sockport;
	close($socket);
	$port;
};
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args, timeout => 5 );
};

# tcp
my $return = $run->( 'tcp', '-H', '127.0.0.1', '-p', $plain_port, '-e', '220 ', '-q', 'QUIT\r\n' );
is( $return->{code}, 0, 'banner' );
like( $return->{stdout}, qr/\ATCP OK - connected to 127.0.0.1:$plain_port in [0-9.]+ seconds \| time=[0-9.]+s;;;0\n\z/,
	'output' );
is(
	$run->( 'tcp', '-H', '127.0.0.1', '-p', $plain_port, '-s', 'PING\r\n', '-e', '+PONG', '-A', '-e', '220' )
		->{code},
	0,
	'send, then all of expect'
);
$return = $run->( 'tcp', '-H', '127.0.0.1', '-p', $plain_port, '-e', 'SSH-', '-t', 1 );
is( $return->{code}, 2, 'not what was expected' );
like( $return->{stdout}, qr/, did not get "SSH-", got "220 test ready"/, 'and what it got' );
like( $run->( 'tcp', '-H', '127.0.0.1', '-p', $closed_port )->{stdout},
	qr/\ATCP CRITICAL - 127.0.0.1:$closed_port, .*refused/i, 'refused' );
is(
	$run->( 'tcp', '-H', '127.0.0.1', '-p', $tls_port, '-S', '--ca-file', $paths->{ca} . '.pem', '-e', '* OK' )
		->{code},
	0,
	'over TLS'
);
like(
	$run->( 'tcp', '-H', '127.0.0.1', '-p', $tls_port, '-S', '-t', 2 )->{stdout},
	qr/\ATCP CRITICAL - .*verify failed/,
	'TLS with a untrusted certificate'
);
is( $run->( 'tcp', '-H', '127.0.0.1', '-p', $tls_port, '-S', '--insecure', '-e', '* OK' )->{code},
	0, 'TLS, --insecure' );
is( $run->( 'tcp', '-H', '127.0.0.1', '-p', 70000 )->{code}, 3, 'bad port' );

# https_cert
my @cert = ( '-H', '127.0.0.1', '-p', $tls_port, '--ca-file', $paths->{ca} . '.pem' );
$return = $run->( 'https_cert', @cert, '-n', 'www.example.org' );
is( $return->{code}, 1, '20 days left is WARNING' );
like(
	$return->{stdout},
	qr/\AHTTPS_CERT WARNING - 127.0.0.1:$tls_port "www.example.org" expires in 20 days, [0-9: -]+ UTC, issued by "Test CA" \| days=20;30;14\n\z/,
	'output'
);
is( $run->( 'https_cert', @cert, '-w', 10, '-c', 5 )->{code}, 0, 'OK, checked against the IP' );
is( $run->( 'https_cert', @cert, '-c', 25 )->{code}, 2, 'CRITICAL' );
like(
	$run->( 'https_cert', @cert, '-n', 'shop.example.org' )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - .*hostname verification failed/,
	'name not covered'
);
like( $run->( 'https_cert', '-H', '127.0.0.1', '-p', $tls_port )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - .*verify failed/, 'untrusted' );
is(
	$run->(
		'https_cert', '-H', '127.0.0.1', '-p', $tls_port, '--insecure', '-n', 'shop.example.org', '-w', 10, '-c', 5
	)->{code},
	0,
	'--insecure only checks the days'
);
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $closed_port )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - 127.0.0.1:$closed_port, /,
	'not connecting'
);
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $plain_port, '-t', 2 )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - /,
	'not TLS'
);

# STARTTLS
foreach my $protocol ( 'smtp', 'imap', 'pop3', 'ftp', 'ldap' ) {
	$return = $run->(
		'https_cert', '-H',      '127.0.0.1', '-p', $starttls_ports{$protocol},
		'-s',         $protocol, '--ca-file', $paths->{ca} . '.pem',
		'-w',         10,        '-c',        5
	);
	is( $return->{code}, 0, 'STARTTLS over ' . $protocol ) || diag( $return->{combined} );
}
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $starttls_ports{smtp_no_tls}, '-s', 'smtp' )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - 127.0.0.1:\d+ smtp does not offer STARTTLS\n\z/,
	'SMTP without STARTTLS'
);
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $starttls_ports{ldap_refused}, '-s', 'ldap' )->{stdout},
	qr/ldap refused TLS, result code 52\n\z/,
	'LDAP refusing'
);
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $plain_port, '-s', 'imap', '-t', 2 )->{stdout},
	qr/imap greeted with "220 test ready"/,
	'not IMAP'
);
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $closed_port, '-s', 'smtp' )->{stdout},
	qr/\AHTTPS_CERT CRITICAL - 127.0.0.1:$closed_port, .*refused/i,
	'STARTTLS not connecting'
);
is( $run->( 'https_cert', '-H', '127.0.0.1', '-s', 'gopher' )->{code}, 3, 'bad --starttls' );
my @helo = ( '-H', '127.0.0.1', '-p', $starttls_ports{smtp_helo}, '-s', 'smtp', '--helo-name', 'client.example.org' );
is( $run->( 'https_cert', @helo, '--ca-file', $paths->{ca} . '.pem', '-w', 10, '-c', 5 )->{code},
	0, '--helo-name given in EHLO' );
like(
	$run->( 'https_cert', '-H', '127.0.0.1', '-p', $starttls_ports{smtp_helo}, '-s', 'smtp' )->{stdout},
	qr/smtp EHLO got ""/,
	'a server wanting a other name'
);
is( $run->( 'tls_protocols', @helo, '-a', 'TLSv1_2' )->{code}, 0, 'tls_protocols --helo-name' );
is( $run->( 'https_cert', '-H', '127.0.0.1', '-s', 'smtp', '--helo-name', 'not a host' )->{code}, 3,
	'bad --helo-name' );

# smtp over TLS, noting what it asks for through SNI
my %sni;
{
	no warnings 'redefine';
	my ( $new, $start_ssl ) = ( IO::Socket::SSL->can('new'), IO::Socket::SSL->can('start_SSL') );
	local *IO::Socket::SSL::new = sub { my ( $class, %args ) = @_; $sni{new} = $args{SSL_hostname}; return $new->(@_) };
	local *IO::Socket::SSL::start_SSL = sub {
		my ( $class, $socket, %args ) = @_;
		$sni{start_SSL} = $args{SSL_hostname};
		return $start_ssl->(@_);
	};
	my @smtp = ( 'smtp', '-H', '127.0.0.1', '--ca-file', $paths->{ca} . '.pem', '-n', 'client.example.org' );
	$return = $run->( @smtp, '-p', $smtps_port, '-S' );
	is( $return->{code}, 0, 'smtp over TLS' ) || diag( $return->{combined} );
	like( $return->{stdout},
		qr/\ASMTP OK - 127.0.0.1:$smtps_port 220 mail.example.org ESMTP, in [0-9.]+ seconds \| time=/, 'output' );
	is( $sni{new}, '', 'no SNI for a IP' );
	$return = $run->( @smtp, '-p', $starttls_ports{smtp}, '-s' );
	is( $return->{code}, 0, 'smtp through STARTTLS' ) || diag( $return->{combined} );
	like( $return->{stdout}, qr/ seconds, over STARTTLS \| time=/, 'and says so' );
	is( $sni{start_SSL}, '', 'no SNI for a IP through STARTTLS' );
	like(
		$run->( 'smtp', '-H', '127.0.0.1', '-p', $smtps_port, '-S', '-t', 2 )->{stdout},
		qr/\ASMTP CRITICAL - 127.0.0.1:$smtps_port, .*verify failed/,
		'TLS with a untrusted certificate'
	);
	local *IO::Socket::SSL::new = sub { my ( $class, %args ) = @_; $sni{new} = $args{SSL_hostname}; return undef };
	$run->( 'smtp', '-H', 'mail.example.org', '-S', '--insecure' );
	is( $sni{new}, 'mail.example.org', 'SNI with the name, --insecure or not' );
}

done_testing();
