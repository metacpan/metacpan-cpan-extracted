package Monitoring::Sneck::Checks::https_cert;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::https_cert - checks the certificate a TLS server hands out

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# The port for each protocol --starttls takes, used if --port is not given.
our %STARTTLS_PORTS = ( smtp => 25, imap => 143, pop3 => 110, ftp => 21, ldap => 389 );

# The LDAP StartTLS extended request, message ID 1, as BER.
our $LDAP_STARTTLS = pack( 'H*', '301d02010177188016' ) . '1.3.6.1.4.1.1466.20037';

=head1 SYNOPSIS

    www_cert|perl:https_cert -H www.example.org
    ldaps_cert|perl:https_cert -H ldap.example.org -p 636 -w 45 -c 20
    vhost_cert|perl:https_cert -H 192.0.2.10 -n shop.example.org
    internal_cert|perl:https_cert -H intranet.example.org --ca-file /usr/local/etc/ssl/internal-ca.pem
    mail_cert|perl:https_cert -H mail.example.org -s smtp
    imap_cert|perl:https_cert -H mail.example.org -s imap -w 45

=head1 DESCRIPTION

Connects through L<IO::Socket::SSL> and checks the certificate the
server hands out. It must be signed by a trusted CA and cover the name,
unless --insecure is given, else it is CRITICAL, as is expired or not
good yet. Then it is WARNING or CRITICAL by the days left.

Any TLS port works, not only 443. With --starttls, it connects in the
clear and asks for TLS the way that protocol does, which for SMTP needs
STARTTLS in the EHLO reply. Not being able to is CRITICAL.

=head1 OPTIONS

- -H, --hostname :: The host to connect to. Required.

- -p, --port :: The port.
Default :: 443, or for --starttls, the protocol's

- -s, --starttls :: Ask for TLS through smtp, imap, pop3, ftp, or ldap.

- --helo-name :: The name to give in EHLO, for --starttls smtp.
Default :: the host name of this host

- -n, --sni :: The name to ask for and check the certificate covers.
Default :: --hostname

- -w, --warning :: Days left at or under which it is WARNING.
Default :: 30

- -c, --critical :: Days left at or under which it is CRITICAL.
Default :: 14

- --insecure :: Only check when it expires, not who signed it or the
name.

- --ca-file :: The CA file to check it against.

=cut

sub option_spec {
	return (
		'hostname|H=s', 'port|p=i',     'sni|n=s',  'starttls|s=s', 'helo-name=s',
		'warning|w=i',  'critical|c=i', 'insecure', 'ca-file=s'
	);
}

sub defaults { return { warning => 30, critical => 14 } }

sub required { return ('hostname') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'hostname', 'sni', 'helo-name' ) {
		push( @problems, '--' . $name . ' "' . $options->{$name} . '" is not a IP or hostname' )
			if defined( $options->{$name} ) && !$self->is_host( $options->{$name} );
	}
	push( @problems, '--port must be 1 to 65535' )
		if defined( $options->{port} ) && ( $options->{port} < 1 || $options->{port} > 65535 );
	push( @problems, '--starttls must be ' . join( ', ', sort( keys(%STARTTLS_PORTS) ) ) )
		if defined( $options->{starttls} ) && !$STARTTLS_PORTS{ $options->{starttls} };

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require IO::Socket::SSL;
	require Data::Validate::IP;
	my $starttls = $self->opt('starttls');
	my $port     = $self->opt('port') // ( defined($starttls) ? $STARTTLS_PORTS{$starttls} : 443 );
	my $name     = $self->opt('sni')  // $self->opt('hostname');
	my $where    = $self->opt('hostname') . ':' . $port;
	my %ssl      = (
		Timeout         => $self->timeout,
		SSL_verify_mode => $self->opt('insecure') ? 0 : 1,
	);
	$ssl{SSL_hostname} = Data::Validate::IP::is_ip($name) ? '' : $name;

	if ( !$self->opt('insecure') ) {
		$ssl{SSL_verifycn_name}   = $name;
		$ssl{SSL_verifycn_scheme} = 'http';
	}
	$ssl{SSL_ca_file} = $self->opt('ca-file') if defined( $self->opt('ca-file') );

	my $socket;
	if ( defined($starttls) ) {
		require IO::Socket::IP;
		my $plain = IO::Socket::IP->new(
			PeerHost => $self->opt('hostname'),
			PeerPort => $port,
			Proto    => 'tcp',
			Timeout  => $self->timeout,
		);
		if ( !defined($plain) ) {
			return $self->finish( $self->CRITICAL, $where . ', ' . ( $@ || $! ) );
		}
		$plain->autoflush(1);
		my $problem = $self->starttls( $plain, $starttls );
		if ( defined($problem) ) {
			close($plain);
			return $self->finish( $self->CRITICAL, $where . ' ' . $starttls . ' ' . $problem );
		}
		$socket = IO::Socket::SSL->start_SSL( $plain, %ssl );
	} else {
		$socket = IO::Socket::SSL->new( PeerHost => $self->opt('hostname'), PeerPort => $port, %ssl );
	}
	if ( !$socket ) {
		return $self->finish( $self->CRITICAL, $where . ', ' . IO::Socket::SSL::errstr() );
	}
	my $cert = $socket->peer_certificate;
	if ( !$cert ) {
		close($socket);
		return $self->finish( $self->CRITICAL, $where . ' handed out no certificate' );
	}
	my $details = $self->cert_details($cert);
	close($socket);

	my ( $code, $message ) = $self->cert_status( $details, $self->opt('warning'), $self->opt('critical') );
	$self->perfdata(
		label    => 'days',
		value    => $details->{days_left},
		warning  => $self->opt('warning'),
		critical => $self->opt('critical')
	);

	return $self->finish( $code, $where . ' ' . $message . ', issued by "' . $details->{issuer} . '"' );
} ## end sub check

=head2 starttls

Asks for TLS on a socket connected in the clear.

- socket :: The socket.

- protocol :: smtp, imap, pop3, ftp, or ldap.

Returns undef once the server said yes, else what went wrong.

    my $problem = $check->starttls( $socket, 'smtp' );

=cut

sub starttls {
	my ( $self, $socket, $protocol ) = @_;

	# a full reply, the last line of a multi line one having a space after the code
	my $coded = sub { return $_[0]             =~ /^\d{3} [^\n]*\n/m };
	my $line  = sub { return $_[0]             =~ /\n/ };
	my $first = sub { my ($reply) = @_; $reply =~ s/\r?\n.*\z//s; return '"' . $reply . '"' };

	if ( $protocol eq 'smtp' || $protocol eq 'ftp' ) {
		my $greeting = $self->read_socket( $socket, $coded );
		return 'greeted with ' . $first->($greeting) if $greeting !~ /^220 /m;
		if ( $protocol eq 'smtp' ) {
			require Sys::Hostname;
			print $socket 'EHLO ' . ( $self->opt('helo-name') // Sys::Hostname::hostname() ) . "\r\n";
			my $ehlo = $self->read_socket( $socket, $coded );
			return 'EHLO got ' . $first->($ehlo) if $ehlo !~ /^250 /m;
			return 'does not offer STARTTLS'     if $ehlo !~ /^250[ -]STARTTLS\s*$/mi;
			print $socket "STARTTLS\r\n";
		} else {
			print $socket "AUTH TLS\r\n";
		}
		my $reply = $self->read_socket( $socket, $coded );
		return 'refused TLS, ' . $first->($reply) if $reply !~ /^2(?:20|34) /m;
	} elsif ( $protocol eq 'imap' ) {
		my $greeting = $self->read_socket( $socket, $line );
		return 'greeted with ' . $first->($greeting) if $greeting !~ /^\* OK/;
		print $socket "a1 STARTTLS\r\n";
		my $reply = $self->read_socket( $socket, sub { return $_[0] =~ /^a1 [^\n]*\n/m } );
		return 'refused TLS, ' . $first->( $reply =~ s/\A.*?^(a1 )/$1/msr ) if $reply !~ /^a1 OK/m;
	} elsif ( $protocol eq 'pop3' ) {
		my $greeting = $self->read_socket( $socket, $line );
		return 'greeted with ' . $first->($greeting) if $greeting !~ /^\+OK/;
		print $socket "STLS\r\n";
		my $reply = $self->read_socket( $socket, $line );
		return 'refused TLS, ' . $first->($reply) if $reply !~ /^\+OK/;
	} else {
		print $socket $LDAP_STARTTLS;
		my $reply = $self->read_socket( $socket, sub { return $_[0] =~ /\x78.*?\x0a\x01./s } );
		return 'got no StartTLS reply'               if $reply !~ /\x78.*?\x0a\x01(.)/s;
		return 'refused TLS, result code ' . ord($1) if $1 ne "\x00";
	}

	return undef;
} ## end sub starttls

1;
