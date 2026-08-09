package Net::Firewall::BlockerHelper::Util;

use 5.006;
use strict;
use warnings;
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::Util - Shared internal helpers mixed into the frontend and backends.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

This module is not used directly. It is a stateless mixin holding the internal
helpers that would otherwise be copy/pasted into every backend. Both
L<Net::Firewall::BlockerHelper> and each backend under
L<Net::Firewall::BlockerHelper>::backends inherit from it alongside
L<Error::Helper>.

    package Net::Firewall::BlockerHelper::backends::foo;

    use base qw( Error::Helper Net::Firewall::BlockerHelper::Util );

    # ...

    sub ban_cidr {
        my ( $self, %opts ) = @_;

        if ( !$self->_valid_cidr( $opts{ban} ) ) {
            # ... raise error 26 ...
        }
    }

=head1 DESCRIPTION

Everything here is an internal helper and carries a leading underscore. None of
it is part of the public API and none of it is expected to be called from
outside of the frontend or a backend. There is no constructor and no state is
kept; the methods only exist here so that a single definition is shared instead
of being duplicated per backend.

=cut

# Internal helper. Returns a JSON object configured the way every backend that
# speaks a JSON REST API wants it, used both to encode request bodies and to
# decode responses.
#
# JSON is used rather than JSON::PP directly because it picks JSON::XS as its
# backend when that is installed and only falls back to the pure perl JSON::PP
# when it is not, so the fast path is taken wherever it is available. The
# object interface used here is the same either way.
#
# Two options are set. canonical makes the encoder sort object keys, so the
# same data always encodes to the same string; without it the key order follows
# the hash order and the bodies recorded in test_data would vary run to run and
# could not be compared against a fixed expected string. utf8 makes the encoder
# emit UTF-8 encoded octets and the decoder expect them, which is what wants to
# be handed to and taken from an HTTP layer.
#
# JSON is pulled in with require at call time rather than use at compile time,
# matching how the HTTP backends load LWP::UserAgent. Only the JSON speaking
# backends ever need it, so it stays off the path of the many backends that do
# not and is a recommends rather than a hard prereq.
#
# Takes no arguments.
#
# Returns a JSON object. A new object is built on every call and nothing is
# cached, so the caller may reconfigure the returned object freely without
# affecting anything else.
#
#     my $body = $self->_json->encode( { name => $name, ip => $ip } );
#
#     my $decoded = $self->_json->decode($response_content);
#     my $id      = $decoded->{result}{id};
sub _json {
	my ($self) = @_;

	require JSON;
	return JSON->new->canonical->utf8;
}

# Internal helper. Returns the conntrack commands that tear down the passed
# IP's existing connections, used by the backends whose kill option drops
# connection tracking entries.
#
# Blocking an address only stops new connections. Anything already established
# keeps flowing, because the block rules match the source but established
# traffic has already been accepted and is tracked. Dropping the conntrack
# entries is what actually cuts an attacker off mid session.
#
# The kill is scoped to whatever is actually being blocked rather than
# indiscriminately dropping every entry for the address. With protocols
# configured, one command is emitted per protocol. With ports but no
# protocols, tcp and udp are assumed, matching the default the rule builders
# use in the same situation. With neither, everything is being blocked, so a
# single unscoped command drops every entry for the address.
#
# Protocols conntrack cannot filter by are skipped rather than emitted and
# left to fail. The mapping also folds the several spellings of IPv6 ICMP onto
# one conntrack name, and duplicates are suppressed, so listing both icmp6 and
# ipv6-icmp produces one command rather than two identical ones. ICMP of the
# wrong family is skipped, since an IPv4 address can have no icmpv6 entries
# and vice versa.
#
# This lives here because the iptables, nftables, and firewalld backends all
# want exactly this. A backend whose kill works differently overrides it: see
# the ufw backend, which offers an ss based mode as well and supports a
# narrower protocol set.
#
# Args:
#
#     ip - The address whose connections should be dropped, as a plain string.
#          Expected to be an already validated and lowercased IPv4 or IPv6
#          address. The family is decided by matching against $IPv4_re and
#          controls both the -f flag and which ICMP protocols are relevant.
#
# Returns the commands as a list of strings, ready to hand to the runner. One
# entry per applicable protocol, or a single unscoped entry when nothing is
# configured. May be empty if every configured protocol was filtered out, for
# instance an IPv4 instance configured only for ipv6-icmp; callers run
# whatever comes back and do not depend on there being any.
#
#     # nothing configured: drop every entry for the address
#     $self->_kill_commands('10.0.0.1');
#     #   conntrack -D -s 10.0.0.1
#
#     # IPv6 needs the family stated, as conntrack defaults to IPv4
#     $self->_kill_commands('2001:db8::1');
#     #   conntrack -f ipv6 -D -s 2001:db8::1
#
#     # protocols tcp and udp
#     $self->_kill_commands('10.0.0.1');
#     #   conntrack -D -p tcp -s 10.0.0.1
#     #   conntrack -D -p udp -s 10.0.0.1
#
#     # ports 22 with no protocols, so tcp and udp are assumed
#     #   conntrack -D -p tcp -s 10.0.0.1
#     #   conntrack -D -p udp -s 10.0.0.1
sub _kill_commands {
	my ( $self, $ip ) = @_;

	# conntrack defaults to IPv4, so IPv6 IPs need the family specified
	my $is_v4  = ( $ip =~ /\A$IPv4_re\z/ ) ? 1  : 0;
	my $family = $is_v4                    ? '' : '-f ipv6 ';

	my @protos = @{ $self->{protocols} };
	if ( !@protos && defined( $self->{ports}[0] ) ) {
		# ports without protocols means tcp and udp are being blocked
		@protos = ( 'tcp', 'udp' );
	}

	# nothing configured means everything is being blocked, so drop every
	# entry for the IP
	if ( !@protos ) {
		return ( 'conntrack ' . $family . '-D -s ' . $ip );
	}

	# scope the kill to the blocked protocols; ones conntrack can not filter
	# by are skipped as are the icmps of the wrong family
	my %conntrack_protos = (
		tcp         => 'tcp',
		udp         => 'udp',
		udplite     => 'udplite',
		sctp        => 'sctp',
		dccp        => 'dccp',
		gre         => 'gre',
		icmp        => 'icmp',
		icmpv6      => 'icmpv6',
		icmp6       => 'icmpv6',
		'ipv6-icmp' => 'icmpv6',
	);

	my @commands;
	my %seen;
	foreach my $proto (@protos) {
		my $conntrack_proto = $conntrack_protos{$proto};
		next if ( !defined($conntrack_proto) );
		next if ( $conntrack_proto eq 'icmp'   && !$is_v4 );
		next if ( $conntrack_proto eq 'icmpv6' && $is_v4 );
		next if ( $seen{$conntrack_proto} );
		$seen{$conntrack_proto} = 1;
		push( @commands, 'conntrack ' . $family . '-D -p ' . $conntrack_proto . ' -s ' . $ip );
	}

	return @commands;
} ## end sub _kill_commands

# Internal helper. Percent encodes a string for use in a URL, so that the dist
# does not need URI::Escape as a dependency for the handful of backends that
# build URLs.
#
# Every character outside the RFC 3986 unreserved set (A-Z, a-z, 0-9, "-", ".",
# "_", and "~") is replaced with a percent sign and its two digit uppercase hex
# value. Note that this includes "/", which becomes %2F, so this escapes a
# single path segment or query value and must not be run over a whole URL or an
# already assembled path.
#
# The encoding is byte oriented, using ord on each character. Input is expected
# to be bytes, which is all the callers ever pass, being IP addresses and
# configured object names. A string holding wide characters would produce more
# than two hex digits for those characters and would need encoding to UTF-8
# octets first.
#
# Args:
#
#     string - The scalar to encode. Expected to be a defined, non-reference
#              string of bytes. Passing undef warns and returns undef under
#              warnings, so callers check for a value first.
#
# Returns the percent encoded string. The argument is not modified in place;
# the copy taken off @_ is what gets edited and returned. A string made up
# entirely of unreserved characters comes back unchanged.
#
#     $self->_uri_escape('10.0.0.1');        # 10.0.0.1, unreserved throughout
#     $self->_uri_escape('2001:db8::1');     # 2001%3Adb8%3A%3A1
#     $self->_uri_escape('10.0.0.0/8');      # 10.0.0.0%2F8
#     $self->_uri_escape('ssh bans');        # ssh%20bans
#
#     # building a URL from a name that may hold anything
#     my $url = $self->_base_url . '/lists/' . $self->_uri_escape($name);
sub _uri_escape {
	my ( $self, $string ) = @_;

	$string =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;

	return $string;
}

# Internal helper. Tests whether a scalar is a syntactically valid IPv4 or IPv6
# CIDR range. This is the validation used by ban_cidr, unban_cidr, and the
# frontend before a range is handed to a backend, so that a malformed range is
# rejected with an error rather than being pasted into a firewall command.
#
# A valid range is an address, a literal "/", and a decimal prefix length that
# is within the range allowed for the address family. The address is matched
# against $IPv4_re from Regexp::IPv4 and $IPv6_re from Regexp::IPv6, anchored,
# so a bare address with no "/" is not valid and neither is a range with any
# leading or trailing whitespace. The prefix length must be one to three digits
# and be 0 to 32 for IPv4 or 0 to 128 for IPv6. The prefix is not required to
# be the canonical network address for the range, so "10.0.0.1/8" is accepted
# as valid; masking off the host bits, if wanted, is left to the backend.
#
# Args:
#
#     cidr - The scalar to test. Any value may be passed. Undef, a reference of
#            any kind, and a string that does not match the format above are
#            all simply not valid rather than fatal.
#
# Returns 1 if the scalar is a valid IPv4 or IPv6 CIDR range and 0 if it is
# not. The return is always one of those two values and is never undef, so it
# is safe to use directly in a boolean test or to store as a flag.
#
#     $self->_valid_cidr('10.0.0.0/8');           # 1
#     $self->_valid_cidr('2001:db8::/32');        # 1
#     $self->_valid_cidr('10.0.0.1/8');           # 1, host bits are allowed
#
#     $self->_valid_cidr('10.0.0.0/33');          # 0, prefix too large for v4
#     $self->_valid_cidr('2001:db8::/129');       # 0, prefix too large for v6
#     $self->_valid_cidr('10.0.0.0');             # 0, no prefix
#     $self->_valid_cidr('not an address/8');     # 0, address does not match
#     $self->_valid_cidr( [ '10.0.0.0/8' ] );     # 0, a reference
#     $self->_valid_cidr(undef);                  # 0
sub _valid_cidr {
	my ( $self, $cidr ) = @_;

	return 0 if ( !defined($cidr) || ref($cidr) ne '' );

	if ( $cidr =~ m!\A(.+)/([0-9]{1,3})\z! ) {
		my ( $addr, $prefix ) = ( $1, $2 );
		return 1 if ( $addr =~ /\A$IPv4_re\z/ && $prefix <= 32 );
		return 1 if ( $addr =~ /\A$IPv6_re\z/ && $prefix <= 128 );
	}

	return 0;
} ## end sub _valid_cidr

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Firewall::BlockerHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Firewall-BlockerHelper>

=item * Search CPAN

L<https://metacpan.org/release/Net-Firewall-BlockerHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper::Util
