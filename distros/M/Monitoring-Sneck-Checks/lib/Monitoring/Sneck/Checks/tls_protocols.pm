package Monitoring::Sneck::Checks::tls_protocols;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::tls_protocols - checks what TLS versions a server takes

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# The versions, by the names IO::Socket::SSL takes, and how they are said.
our @VERSIONS = (
	[ 'SSLv3',   'SSLv3' ],
	[ 'TLSv1',   'TLSv1.0' ],
	[ 'TLSv1_1', 'TLSv1.1' ],
	[ 'TLSv1_2', 'TLSv1.2' ],
	[ 'TLSv1_3', 'TLSv1.3' ]
);
our %SAID = map { $_->[0] => $_->[1] } @VERSIONS;

=head1 SYNOPSIS

    www_tls|perl:tls_protocols -H www.example.org
    mail_tls|perl:tls_protocols -H mail.example.org -s smtp -a TLSv1_2 -a TLSv1_3
    ldaps_tls|perl:tls_protocols -H ldap.example.org -p 636 -r TLSv1 -r TLSv1_1 -r SSLv3

=head1 DESCRIPTION

Tries each TLS version given on its own, through L<IO::Socket::SSL>. A
version in --refuse that the server takes, or one in --accept that it
does not, is CRITICAL.

Every version is tried with OpenSSL's security level set to 0, as
otherwise this side would refuse the old ones, not the server. A version this
host's OpenSSL can not do at all, as is common for SSLv3, is UNKNOWN,
as it can not be told if the server takes it. So is not being able
to connect, or STARTTLS failing, as nothing could be tried.

The certificate is not checked, see L<Monitoring::Sneck::Checks::https_cert>
for that. --starttls works the same as there.

=head1 OPTIONS

- -H, --hostname :: The host. Required.

- -p, --port :: The port.
Default :: 443, or for --starttls, the protocol's

- -n, --sni :: The name to ask for.
Default :: --hostname

- -s, --starttls :: Ask for TLS through smtp, imap, pop3, ftp, or ldap.

- --helo-name :: The name to give in EHLO, for --starttls smtp.
Default :: the host name of this host

- -r, --refuse :: A version it must not take, SSLv3, TLSv1, TLSv1_1,
TLSv1_2, or TLSv1_3. May be given more than once.
Default :: TLSv1 and TLSv1_1, unless --accept is given

- -a, --accept :: A version it must take. May be given more than once.

=cut

sub option_spec {
	return ( 'hostname|H=s', 'port|p=i', 'sni|n=s', 'starttls|s=s', 'helo-name=s', 'refuse|r=s@', 'accept|a=s@' );
}

sub required { return ('hostname') }

sub validate {
	my ( $self, $options ) = @_;

	require Monitoring::Sneck::Checks::https_cert;
	my @problems;
	foreach my $name ( 'hostname', 'sni', 'helo-name' ) {
		push( @problems, '--' . $name . ' "' . $options->{$name} . '" is not a IP or hostname' )
			if defined( $options->{$name} ) && !$self->is_host( $options->{$name} );
	}
	foreach my $name ( 'refuse', 'accept' ) {
		foreach my $version ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $version . '" must be ' . join( ', ', map { $_->[0] } @VERSIONS ) )
				if !$SAID{$version};
		}
	}
	push( @problems,
		'--starttls must be ' . join( ', ', sort( keys(%Monitoring::Sneck::Checks::https_cert::STARTTLS_PORTS) ) ) )
		if defined( $options->{starttls} )
		&& !$Monitoring::Sneck::Checks::https_cert::STARTTLS_PORTS{ $options->{starttls} };

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @refuse = @{ $self->opt('refuse') // ( defined( $self->opt('accept') ) ? [] : [ 'TLSv1', 'TLSv1_1' ] ) };
	my @accept = @{ $self->opt('accept') // [] };
	my ( @taken, @refused, @should_refuse, @should_take, @untried );
	foreach my $version ( map { $_->[0] } @VERSIONS ) {
		next if !grep { $_ eq $version } @refuse, @accept;
		my ( $taken, $why ) = $self->try($version);
		if ( !defined($taken) ) {
			push( @untried, $SAID{$version} . ', ' . $why );
			next;
		}
		push( @{ $taken ? \@taken : \@refused }, $SAID{$version} );
		push( @should_refuse, $SAID{$version} ) if $taken  && grep { $_ eq $version } @refuse;
		push( @should_take,   $SAID{$version} ) if !$taken && grep { $_ eq $version } @accept;
	} ## end foreach my $version ( map { $_->[0] } @VERSIONS)

	my @codes = ( $self->OK );
	push( @codes, $self->CRITICAL ) if defined( $should_refuse[0] ) || defined( $should_take[0] );
	push( @codes, $self->UNKNOWN )  if defined( $untried[0] );
	my @parts;
	push( @parts, 'takes ' . join( ', ', @taken ) )                 if defined( $taken[0] );
	push( @parts, 'refuses ' . join( ', ', @refused ) )             if defined( $refused[0] );
	push( @parts, 'should refuse ' . join( ', ', @should_refuse ) ) if defined( $should_refuse[0] );
	push( @parts, 'should take ' . join( ', ', @should_take ) )     if defined( $should_take[0] );
	push( @parts, 'could not try ' . join( '; ', @untried ) )       if defined( $untried[0] );

	return $self->finish( $self->worst(@codes),
		$self->opt('hostname') . ':' . $self->port . ' ' . join( ', ', @parts ) );
} ## end sub check

=head2 port

Returns the port, --port, or the default for --starttls, or 443.

=cut

sub port {
	my ($self) = @_;

	return $self->opt('port') if defined( $self->opt('port') );
	return $Monitoring::Sneck::Checks::https_cert::STARTTLS_PORTS{ $self->opt('starttls') }
		if defined( $self->opt('starttls') );

	return 443;
}

=head2 try

Tries a version.

Returns 1 if the server takes it, 0 and why if not, or undef and why if
it could not be tried, as for this host's OpenSSL not doing it, or not
being able to connect at all.

=cut

sub try {
	my ( $self, $version ) = @_;

	require IO::Socket::SSL;
	require IO::Socket::IP;
	require Data::Validate::IP;
	my $name = $self->opt('sni') // $self->opt('hostname');
	my %ssl  = (
		SSL_version     => $version,
		SSL_verify_mode => 0,
		SSL_cipher_list => 'ALL:@SECLEVEL=0',
		SSL_hostname    => Data::Validate::IP::is_ip($name) ? '' : $name,
		Timeout         => $self->timeout,
	);

	my $plain = IO::Socket::IP->new(
		PeerHost => $self->opt('hostname'),
		PeerPort => $self->port,
		Proto    => 'tcp',
		Timeout  => $self->timeout
	);
	return ( undef, 'can not connect, ' . ( $@ || $! ) ) if !$plain;
	if ( defined( $self->opt('starttls') ) ) {
		$plain->autoflush(1);
		my $problem = Monitoring::Sneck::Checks::https_cert::starttls( $self, $plain, $self->opt('starttls') );
		if ( defined($problem) ) {
			close($plain);
			return ( undef, $self->opt('starttls') . ' ' . $problem );
		}
	}
	my $socket = IO::Socket::SSL->start_SSL( $plain, %ssl );
	if ($socket) {
		close($socket);
		return (1);
	}
	my $why = IO::Socket::SSL::errstr() // 'unknown error';
	close($plain);

	# this side not being able to do it at all, not the server saying no
	return ( undef, 'this host can not do it, ' . $why )
		if $why
		=~ /no protocols available|null ssl method|unknown option|invalid SSL_version|SSL Version \S+ not supported/i;

	return ( 0, $why );
} ## end sub try

1;
