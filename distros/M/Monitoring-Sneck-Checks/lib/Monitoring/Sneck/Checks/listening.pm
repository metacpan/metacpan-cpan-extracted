package Monitoring::Sneck::Checks::listening;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Socket qw(AF_INET AF_INET6 inet_ntop);

=head1 NAME

Monitoring::Sneck::Checks::listening - checks what ports are being listened on

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where sockstat is on FreeBSD. Set by tests.
our $SOCKSTAT = '/usr/bin/sockstat';

=head1 SYNOPSIS

    ssh_listening|perl:listening -p 22
    web_listening|perl:listening -p tcp/80 -p tcp/443 -p udp/443
    !only_expected||perl:listening -p 22 -p 25 -p udp/123 -o -L

=head1 DESCRIPTION

Checks each port given is being listened on, and with --only that
nothing else is. Either is CRITICAL.

Ports are given as [protocol/][address:]port, such as 22, tcp/22,
udp/53, 127.0.0.1:6379, or tcp6/[::1]:25. tcp and udp match either IP
version, while tcp4, tcp6, udp4, and udp6 match only that one. No
address matches any, while a address must match exactly, a wildcard
listener, 0.0.0.0 or ::, counting for any address. For UDP, a bound
socket not connected to anything counts as listening. That includes
clients using unconnected sockets, such as for mDNS, so --only with UDP
may need --ignore for those.

On Linux, sockets are read from /proc/net. On FreeBSD, sockstat -46lqn
is run. Other OSes are UNKNOWN.

=head1 OPTIONS

- -p, --port :: A port that must be listened on. May be given more
than once.

- -o, --only :: Nothing but --port may be listened on.

- -L, --ignore-loopback :: For --only, leave out what only listens on
loopback addresses.

- -i, --ignore :: For --only, a port that may be listened on, given
the same way as --port. May be given more than once.

One of --port or --only must be given.

=cut

sub option_spec { return ( 'port|p=s@', 'only|o', 'ignore-loopback|L', 'ignore|i=s@' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'port', 'ignore' ) {
		foreach my $port ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $port . '" is not [protocol/][address:]port' )
				if !defined( _wanted($port) );
		}
	}
	push( @problems, 'nothing to check, give --port or --only' ) if !defined( $options->{port} ) && !$options->{only};

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @listeners = $self->listeners;
	my @wanted    = map { _wanted($_) } @{ $self->opt('port')   // [] };
	my @ignored   = map { _wanted($_) } @{ $self->opt('ignore') // [] };
	my @problems;
	foreach my $want (@wanted) {
		push( @problems, $want->{text} . ' is not listened on' ) if !grep { _matches( $want, $_ ) } @listeners;
	}

	if ( $self->opt('only') ) {
		my %extra;
		foreach my $listener (@listeners) {
			next if grep { _matches( $_, $listener ) } @wanted, @ignored;
			next if $self->opt('ignore-loopback') && $listener->{address} =~ /\A(?:127\.|::1\z|::ffff:127\.)/;
			$extra{ $listener->{protocol} . '/' . _join_address( $listener->{address}, $listener->{port} ) }
				= $listener;
		}
		my @extra = sort {
				   $extra{$a}{protocol} cmp $extra{$b}{protocol}
				|| $extra{$a}{port} <=> $extra{$b}{port}
				|| $a cmp $b
		} keys(%extra);
		push( @problems, 'also listening on ' . join( ', ', @extra ) ) if defined( $extra[0] );
	} ## end if ( $self->opt('only') )

	my $message = scalar(@listeners) . ' listening';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( defined( $problems[0] ) ? $self->CRITICAL : $self->OK, $message );
} ## end sub check

=head2 listeners

Returns what is listening, as hash refs of protocol, tcp4, tcp6, udp4,
or udp6, address, and port. Dies if it can not be found.

=cut

sub listeners {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my @listeners;
		foreach my $protocol ( 'tcp', 'tcp6', 'udp', 'udp6' ) {
			my $table  = eval { $self->proc_file( 'net/' . $protocol ) } // next;
			my $family = $protocol =~ /6\z/ ? 6 : 4;

			# TCP_LISTEN is 0A, and a unconnected UDP socket is TCP_CLOSE, 07
			my $listening = $protocol =~ /\Atcp/ ? '0A' : '07';
			foreach my $line ( split( /\n/, $table ) ) {
				my ( $local, $state ) = ( split( /\s+/, $line =~ s/\A\s+//r ) )[ 1, 3 ];
				next if !defined($state) || $state ne $listening || $local !~ /\A([0-9A-F]+):([0-9A-F]{4})\z/;
				my ( $hex, $port ) = ( $1, hex($2) );
				push(
					@listeners,
					{
						protocol => ( $protocol =~ s/\d\z//r ) . $family,
						address  => _hex_address( $hex, $family ),
						port     => $port
					}
				);
			} ## end foreach my $line ( split( /\n/, $table ) )
		} ## end foreach my $protocol ( 'tcp', 'tcp6', 'udp', 'udp6')
		return @listeners;
	} ## end if ( $self->os eq 'linux' )
	if ( $self->os eq 'freebsd' ) {
		my ( $exit, $output ) = $self->run_command( $SOCKSTAT, '-46lqn' );
		die( 'sockstat exited ' . $exit . "\n" ) if $exit;

		# USER COMMAND PID FD PROTO LOCAL FOREIGN, with tcp46 and the like for both versions
		my @listeners;
		foreach my $line ( split( /\n/, $output ) ) {
			my ( $protocol, $local ) = ( split( /\s+/, $line ) )[ 4, 5 ];
			next if !defined($local);
			my ( $kind,    $families ) = $protocol =~ /\A(tcp|udp)(4|6|46)\z/ or next;
			my ( $address, $port )     = $local    =~ /\A(.*):([0-9]+)\z/     or next;
			foreach my $family ( split( //, $families ) ) {
				my $at = $address eq '*' ? ( $family eq '6' ? '::' : '0.0.0.0' ) : $address;
				push( @listeners, { protocol => $kind . $family, address => $at, port => $port + 0 } );
			}
		} ## end foreach my $line ( split( /\n/, $output ) )
		return @listeners;
	} ## end if ( $self->os eq 'freebsd' )

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub listeners

# Parses a --port.
#
# Args...
#
#     - text :: The --port, such as 'udp/53' or 'tcp6/[::1]:25'.
#
# Returns a hash ref of text, protocol, tcp, udp, or one of those with 4
# or 6, address, undef for any, and port, or undef if it is not valid.
#
# Example...
#
#     _wanted('127.0.0.1:6379');
#     # { text => '127.0.0.1:6379', protocol => 'tcp', address => '127.0.0.1', port => 6379 }
sub _wanted {
	my ($text) = @_;

	return undef if $text !~ m{\A(?:(tcp|udp)([46]?)/)?(?:\[?([0-9A-Fa-f.:]+?)\]?:)?([0-9]{1,5})\z};
	my ( $kind, $family, $address, $port ) = ( $1 // 'tcp', $2, $3, $4 );
	return undef if $port < 1 || $port > 65535;

	return {
		text     => $text,
		protocol => $kind . ( $family // '' ),
		address  => defined($address) ? lc($address) : undef,
		port     => $port + 0
	};
} ## end sub _wanted

# Checks if a listener is what a --port wants.
#
# Args...
#
#     - want :: From _wanted.
#
#     - listener :: From listeners.
#
# Returns 1 if it matches, else 0.
#
# Example...
#
#     _matches( _wanted('tcp/22'), { protocol => 'tcp6', address => '::', port => 22 } );    # 1
sub _matches {
	my ( $want, $listener ) = @_;

	return 0 if $want->{port} != $listener->{port};
	return 0 if index( $listener->{protocol}, $want->{protocol} ) != 0;
	return 1 if !defined( $want->{address} );
	return 1 if $listener->{address} eq '0.0.0.0' || $listener->{address} eq '::';

	return lc( $listener->{address} ) eq $want->{address} ? 1 : 0;
} ## end sub _matches

# Turns a address from /proc/net into text. Linux prints each 32 bit
# word of it as a number in the host's byte order, so packing each back
# that way gives the bytes as they were, in network order.
#
# Args...
#
#     - hex :: The address as hex, 8 characters for IPv4 or 32 for IPv6.
#
#     - family :: 4 or 6.
#
# Returns the address, such as 127.0.0.1 or ::1.
#
# Example...
#
#     _hex_address( '0100007F', 4 );    # '127.0.0.1', on a little endian host
sub _hex_address {
	my ( $hex, $family ) = @_;

	my $packed = join( '', map { pack( 'L', hex($_) ) } $hex =~ /(.{8})/g );

	return inet_ntop( $family == 6 ? AF_INET6 : AF_INET, $packed );
}

# Joins a address and port, putting [] around IPv6 addresses.
#
# Args...
#
#     - address :: The address.
#
#     - port :: The port.
#
# Returns them joined.
#
# Example...
#
#     _join_address( '::1', 25 );    # '[::1]:25'
sub _join_address {
	my ( $address, $port ) = @_;

	return ( $address =~ /:/ ? '[' . $address . ']' : $address ) . ':' . $port;
}

1;
