package Monitoring::Sneck::Checks::tcp;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::tcp - checks a TCP service

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ssh|perl:tcp -H 192.0.2.10 -p 22 -e SSH-
    smtp|perl:tcp -H mail.example.org -p 25 -e '220 ' -q 'QUIT\r\n'
    imaps|perl:tcp -H mail.example.org -p 993 -S -e '* OK'
    redis|perl:tcp -H 127.0.0.1 -p 6379 -s 'PING\r\n' -e +PONG -w 0.1 -c 0.5

=head1 DESCRIPTION

Connects to a port, optionally over TLS, sends anything given, and
looks for what is expected in what comes back. Not being able to
connect, or not getting what is expected, is CRITICAL.

\r, \n, \t, and \\ in --send and --quit are turned into what they stand for.

=head1 OPTIONS

- -H, --hostname :: The host. Required.

- -p, --port :: The port. Required.

- -S, --ssl :: Connect over TLS.

- -s, --send :: What to send once connected.

- -e, --expect :: Text to look for in what comes back. May be given
more than once, any being found is OK.

- -A, --all :: All of --expect must be found.

- -q, --quit :: What to send before closing.

- -w, --warning :: Range of seconds to connect.

- -c, --critical :: Range of seconds to connect.

- --insecure :: Do not check the certificate for --ssl.

- --ca-file :: The CA file to check the certificate against.

=cut

sub option_spec {
	return (
		'hostname|H=s', 'port|p=i',    'ssl|S',        'send|s=s', 'expect|e=s@', 'all|A',
		'quit|q=s',     'warning|w=s', 'critical|c=s', 'insecure', 'ca-file=s',
	);
}

sub required { return ( 'hostname', 'port' ) }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );
	push( @problems, '--port must be 1 to 65535' )
		if defined( $options->{port} ) && ( $options->{port} < 1 || $options->{port} > 65535 );

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $where = $self->opt('hostname') . ':' . $self->opt('port');
	my $start = Time::HiRes::time;
	my $socket;
	if ( $self->opt('ssl') ) {
		require IO::Socket::SSL;
		my %ssl = (
			PeerHost        => $self->opt('hostname'),
			PeerPort        => $self->opt('port'),
			Timeout         => $self->timeout,
			SSL_verify_mode => $self->opt('insecure') ? 0 : 1,
		);
		$ssl{SSL_ca_file} = $self->opt('ca-file') if defined( $self->opt('ca-file') );
		$socket = IO::Socket::SSL->new(%ssl);
		if ( !defined($socket) ) {
			return $self->finish( $self->CRITICAL, $where . ', ' . IO::Socket::SSL::errstr() );
		}
	} else {
		require IO::Socket::IP;
		$socket = IO::Socket::IP->new(
			PeerHost => $self->opt('hostname'),
			PeerPort => $self->opt('port'),
			Proto    => 'tcp',
			Timeout  => $self->timeout,
		);
		if ( !defined($socket) ) {
			return $self->finish( $self->CRITICAL, $where . ', ' . ( $@ || $! ) );
		}
	} ## end else [ if ( $self->opt('ssl') ) ]
	my $seconds = sprintf( '%.3f', Time::HiRes::time - $start );

	$socket->autoflush(1);
	if ( defined( $self->opt('send') ) ) {
		print $socket _unescape( $self->opt('send') );
	}

	my @codes = ( $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') ) );
	my @problems;
	push( @problems, 'slow' ) if $codes[0] != $self->OK;
	my @expect = @{ $self->opt('expect') // [] };
	if ( defined( $expect[0] ) ) {
		my $received = $self->read_socket(
			$socket,
			sub {
				my @found = grep { index( $_[0], $_ ) >= 0 } @expect;
				return $self->opt('all') ? scalar(@found) == scalar(@expect) : defined( $found[0] );
			}
		);
		my @found = grep { index( $received, $_ ) >= 0 } @expect;
		if ( $self->opt('all') ? scalar(@found) != scalar(@expect) : !defined( $found[0] ) ) {
			my $first = ( split( /\r?\n/, $received ) )[0] // '';
			push( @codes,    $self->CRITICAL );
			push( @problems, 'did not get ' . join( ', ', map { '"' . $_ . '"' } @expect ) . ', got "' . $first . '"' );
		}
	} ## end if ( defined( $expect[0] ) )

	if ( defined( $self->opt('quit') ) ) {
		print $socket _unescape( $self->opt('quit') );
	}
	close($socket);

	$self->perfdata(
		label    => 'time',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $message = 'connected to ' . $where . ' in ' . $seconds . ' seconds';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

# Turns \r, \n, \t, and \\ into what they stand for.
#
# Args...
#
#     - text :: The text, from --send or --quit.
#
# Returns the text with them turned.
#
# Example...
#
#     _unescape('QUIT\r\n');
#     # "QUIT\r\n"
sub _unescape {
	my ($text) = @_;

	my %turned = ( r => "\r", n => "\n", t => "\t", '\\' => '\\' );
	$text =~ s/\\([rnt\\])/$turned{$1}/g;

	return $text;
}

1;
