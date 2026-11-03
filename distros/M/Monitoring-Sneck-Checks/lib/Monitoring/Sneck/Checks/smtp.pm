package Monitoring::Sneck::Checks::smtp;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::smtp - checks a SMTP server

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    smtp|perl:smtp -H mail.example.org
    smtp_tls|perl:smtp -H mail.example.org -s -E SIZE -E PIPELINING -w 1 -c 3
    submissions|perl:smtp -H mail.example.org -p 465 -S -E AUTH
    smtp_banner|perl:smtp -H 192.0.2.25 -e 'ESMTP Postfix'

=head1 DESCRIPTION

Connects, reads the greeting, says EHLO, and QUITs, timing it all. A
greeting other than 220, such as 554 for refusing, a EHLO not answered
with 250, or a extension asked for not being offered, is CRITICAL, as
is not being able to connect.

With --starttls, STARTTLS must be offered, and is done, with EHLO said
again over TLS. With --ssl, it connects over TLS from the start, as for
port 465. The certificate is checked unless --insecure is given. See
L<Monitoring::Sneck::Checks::https_cert> with --starttls smtp for when
it expires.

=head1 OPTIONS

- -H, --hostname :: The host, and the name asked for through SNI,
unless it is a IP. Required.

- -p, --port :: The port.
Default :: 25, or 465 with --ssl

- -S, --ssl :: Connect over TLS. Can not be used with --starttls.

- -s, --starttls :: STARTTLS must be offered, and is done. Can not be
used with --ssl.

- -e, --expect :: Text the greeting must have.

- -E, --extension :: A extension EHLO must offer, such as SIZE, AUTH,
or PIPELINING. May be given more than once.

- -n, --helo-name :: The name to give in EHLO.
Default :: the host name of this host

- -w, --warning :: Range of seconds for the whole of it.

- -c, --critical :: Range of seconds for the whole of it.

- --insecure :: Do not check the certificate.

- --ca-file :: The CA file to check the certificate against.

=cut

sub option_spec {
	return (
		'hostname|H=s',  'port|p=i',    'ssl|S',        'starttls|s', 'expect|e=s', 'extension|E=s@',
		'helo-name|n=s', 'warning|w=s', 'critical|c=s', 'insecure',   'ca-file=s',
	);
}

sub required { return ('hostname') }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );
	push( @problems, '--ssl and --starttls can not both be given' ) if $options->{ssl} && $options->{starttls};
	push( @problems, '--helo-name "' . $options->{'helo-name'} . '" is not a hostname' )
		if defined( $options->{'helo-name'} ) && !$self->is_host( $options->{'helo-name'} );

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require IO::Socket::SSL;
	require IO::Socket::IP;
	require Sys::Hostname;
	require Data::Validate::IP;
	my $host  = $self->opt('hostname');
	my $port  = $self->opt('port') // ( $self->opt('ssl') ? 465 : 25 );
	my $where = $host . ':' . $port;
	my %ssl   = ( SSL_verify_mode => $self->opt('insecure') ? 0 : 1, Timeout => $self->timeout );

	# SNI does not take a IP, and is set either way, as start_SSL has no PeerHost to take it from
	$ssl{SSL_hostname} = Data::Validate::IP::is_ip($host) ? '' : $host;
	if ( !$self->opt('insecure') ) {
		$ssl{SSL_verifycn_name}   = $host;
		$ssl{SSL_verifycn_scheme} = 'smtp';
	}
	$ssl{SSL_ca_file} = $self->opt('ca-file') if defined( $self->opt('ca-file') );

	my $start = Time::HiRes::time;
	my $socket
		= $self->opt('ssl')
		? IO::Socket::SSL->new( PeerHost => $self->opt('hostname'), PeerPort => $port, %ssl )
		: IO::Socket::IP->new(
			PeerHost => $self->opt('hostname'),
			PeerPort => $port,
			Proto    => 'tcp',
			Timeout  => $self->timeout
		);
	if ( !$socket ) {
		return $self->finish( $self->CRITICAL,
			$where . ', ' . ( $self->opt('ssl') ? IO::Socket::SSL::errstr() : ( $@ || $! ) ) );
	}
	$socket->autoflush(1);

	my $greeting = $self->reply($socket);
	if ( $greeting->{code} != 220 ) {
		close($socket);
		return $self->finish( $self->CRITICAL, $where . ' greeted with ' . _first($greeting) );
	}
	my @problems;
	if ( defined( $self->opt('expect') ) && index( $greeting->{text}, $self->opt('expect') ) < 0 ) {
		push( @problems, 'greeting does not have "' . $self->opt('expect') . '"' );
	}

	my $helo = $self->opt('helo-name') // Sys::Hostname::hostname();
	my $ehlo = $self->command( $socket, 'EHLO ' . $helo );
	if ( $ehlo->{code} != 250 ) {
		close($socket);
		return $self->finish( $self->CRITICAL, $where . ' answered EHLO with ' . _first($ehlo) );
	}
	if ( $self->opt('starttls') ) {
		if ( !$ehlo->{extensions}{STARTTLS} ) {
			close($socket);
			return $self->finish( $self->CRITICAL, $where . ' does not offer STARTTLS' );
		}
		my $go = $self->command( $socket, 'STARTTLS' );
		if ( $go->{code} != 220 ) {
			close($socket);
			return $self->finish( $self->CRITICAL, $where . ' answered STARTTLS with ' . _first($go) );
		}
		if ( !IO::Socket::SSL->start_SSL( $socket, %ssl ) ) {
			return $self->finish( $self->CRITICAL, $where . ' STARTTLS failed, ' . IO::Socket::SSL::errstr() );
		}
		$ehlo = $self->command( $socket, 'EHLO ' . $helo );
		if ( $ehlo->{code} != 250 ) {
			close($socket);
			return $self->finish( $self->CRITICAL, $where . ' answered EHLO over TLS with ' . _first($ehlo) );
		}
	} ## end if ( $self->opt('starttls') )
	foreach my $extension ( @{ $self->opt('extension') // [] } ) {
		push( @problems, 'does not offer ' . uc($extension) ) if !$ehlo->{extensions}{ uc($extension) };
	}
	$self->command( $socket, 'QUIT' );
	close($socket);
	my $seconds = sprintf( '%.3f', Time::HiRes::time - $start );

	my @codes     = ( defined( $problems[0] ) ? $self->CRITICAL : $self->OK );
	my $time_code = $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') );
	push( @codes,    $time_code );
	push( @problems, 'slow' ) if $time_code != $self->OK;
	$self->perfdata(
		label    => 'time',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $message
		= $where . ' '
		. _first($greeting) . ', in '
		. $seconds
		. ' seconds'
		. ( $self->opt('starttls') ? ', over STARTTLS' : '' );
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

=head2 command

Sends a SMTP command and reads the reply.

- socket :: The socket.

- command :: The command, without the line ending.

Returns the reply, as from L</reply>.

=cut

sub command {
	my ( $self, $socket, $command ) = @_;

	print $socket $command . "\r\n";

	return $self->reply($socket);
}

=head2 reply

Reads a SMTP reply, all of its lines.

Returns a hash ref of code, 0 if none came, text, the lines without
their codes joined by newlines, and extensions, a hash ref of the
upper cased first word of each line after the first, for EHLO.

=cut

sub reply {
	my ( $self, $socket ) = @_;

	# a full reply, the last line of a multi line one having a space or nothing after the code
	my $read  = $self->read_socket( $socket, sub { return $_[0] =~ /^\d{3}(?: [^\n]*)?\r?\n/m } );
	my @lines = $read =~ /^(\d{3})[ -]?([^\r\n]*)/mg;
	my %reply = ( code => 0, text => '', extensions => {} );
	return \%reply if !@lines;

	my @texts;
	while ( my ( $code, $text ) = splice( @lines, 0, 2 ) ) {
		$reply{code} = $code;
		push( @texts, $text );
	}
	$reply{text} = join( "\n", @texts );
	foreach my $text ( @texts[ 1 .. $#texts ] ) {
		$reply{extensions}{ uc($1) } = 1 if $text =~ /\A(\S+)/;
	}

	return \%reply;
} ## end sub reply

# Describes a reply for messages, its code and first line.
#
# Args...
#
#     - reply :: From reply.
#
# Returns the description, such as '220 mail.example.org ESMTP', or
# 'nothing' if no reply came.
#
# Example...
#
#     _first( { code => 554, text => "no thanks\nbye" } );    # '554 no thanks'
sub _first {
	my ($reply) = @_;

	return 'nothing' if !$reply->{code};

	return $reply->{code} . ' ' . ( split( /\n/, $reply->{text} ) )[0];
}

1;
