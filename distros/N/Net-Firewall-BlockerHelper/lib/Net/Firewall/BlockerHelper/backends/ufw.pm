package Net::Firewall::BlockerHelper::backends::ufw;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::ufw - ufw backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'ufw',
            ports => ['22'],
            protocols => ['tcp'],
            name => 'ssh',
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');
    $fw_helper->teardown;

=head1 DESCRIPTION

Blocks IPs using L<ufw(8)>, the uncomplicated firewall front end common on
Ubuntu.

Unlike the table/set based backends there is no container to create; each
ban prepends one or more per-IP rules (one per protocol) and each unban
deletes them again. teardown removes the rules for all currently banned IPs
without forgetting them, so re_init can re-add them.

ufw must already be enabled (C<ufw enable>); init and check verify this via
C<ufw status>. Requires C<ufw> to be in the C<PATH> of the process, which
must have sufficient privileges to run it.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for furhter info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are ints within the
            range 1 to 65535 or a valid service name via getservbyname. All ports will be
            blocked if non are specified. Duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. This is checked against
            /etc/protocols via the function getprotobyname and against the
            protocols understood by ufw (tcp, udp, ah, esp, gre, igmp, and
            ipv6). Duplicates will be discarded. If no protocols are given,
            everything from the IP is blocked, unless ports are given, in
            which case it defaults to tcp and udp. Ports are only attached to
            tcp and udp; other protocols are blocked without a port.
        - Default :: [], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - type :: The drop method to use. 'deny' silently drops. 'reject' sends
            a reject back. See ufw(8).
        - Default :: deny

    - kill :: Kill existing connections/state for the banned IP. '' does
            nothing, 'ss' uses ss -K, and 'conntrack' uses conntrack -D. Both
            handle IPv4 and IPv6 and both are scoped to the configured
            protocols, so blocking only udp will not kill tcp and vice versa;
            with no protocols configured everything applicable is killed. For
            ss that means -t/-u/-tu as appropriate (TCP connections and
            connected UDP sockets are what ss can kill) and for conntrack -p
            per blocked protocol.
        - Default :: ''

All errors are considered fatal, meaning if new fails it will die.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			# all_fatal is what Error::Helper 2.1.0 actually checks; all_errors_fatal
			# is kept for the name documented in its POD
			all_fatal        => 1,
			flags            => {
				1  => 'notInited',
				2  => 'invalidPortSpecified',
				3  => 'portsNotArray',
				4  => 'protocolsNotArray',
				5  => 'invalidProtocolSpecified',
				6  => 'invalidPrefixSpecified',
				7  => 'invalidName',
				8  => 'optionsNotHash',
				9  => 'noBanItem',
				10 => 'banItemNotIP',
				12 => 'backendInitError',
				13 => 'banFailed',
				14 => 'unbanFailed',
				15 => 'listFailed',
				16 => 'reInitFailed',
				17 => 'teardownFailed',
				18 => 'alreadyInited',
				19 => 'killInvalid',
				20 => 'typeInvalid',
				23 => 'initFailed',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'banCidrFailed',
				27 => 'unbanCidrFailed',
				28 => 'cidrItemNotCidr',
				29 => 'cidrNotSupported',
				30 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options => {
			type => 'deny',
			kill => '',
		},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
		banned_cidr    => {},
		cidr_supported => 1,
	};
	bless $self;

	if ( defined( $opts{ports} ) && ref( $opts{ports} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'ports is defined and type is not array but "' . ref( $opts{ports} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{ports} ) ) {
		my %ports;
		foreach my $item ( @{ $opts{ports} } ) {
			if ( $item =~ /^[0-9]+$/ && $item >= 1 && $item <= 65535 ) {
				$ports{$item} = 1;
			} elsif ( $item =~ /^[0-9]+$/ ) {
				$self->{perror} = 1;
				$self->{error}  = 2;
				$self->{errorString}
					= $item . ' is not a valid value for a port as it must be a int within the range 1 to 65535';
				$self->warn;
			} else {
				# just using tcp here as protocol must be specified
				my ( $name, $aliases, $port, $proto ) = getservbyname( $item, 'tcp' );
				if ( !defined($port) ) {
					$self->{perror} = 1;
					$self->{error}  = 2;
					$self->{errorString}
						= $item . ' could not be resolved to a port name via getservbyname("' . $item . '", "tcp")';
					$self->warn;
				}
				$ports{$port} = 1;
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 &&...)]
		} ## end foreach my $item ( @{ $opts{ports} } )
		my @port_keys = keys(%ports);
		@port_keys = sort { $a <=> $b } @port_keys;
		push( @{ $self->{ports} }, @port_keys );
	} ## end elsif ( defined( $opts{ports} ) )

	# the protocols ufw understands for rules
	my %ufw_protocols = ( tcp => 1, udp => 1, ah => 1, esp => 1, gre => 1, igmp => 1, ipv6 => 1 );

	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 4;
		$self->{errorString} = 'protocols is defined and type is not array but "' . ref( $opts{protocols} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{protocols} ) ) {
		my %protocols;
		foreach my $item ( @{ $opts{protocols} } ) {
			my ( $name, $aliases, $proto ) = getprotobyname($item);
			# if this is undef, it means it is not a known protocol
			if ( !defined($proto) ) {
				$self->{perror} = 1;
				$self->{error}  = 5;
				$self->{errorString}
					= $item . ' could not be resolved to a protocol via getprotobyname("' . $item . '")';
				$self->warn;
			}
			if ( !$ufw_protocols{$item} ) {
				$self->{perror} = 1;
				$self->{error}  = 5;
				$self->{errorString}
					= $item . ' is not a protocol understood by ufw... understood protocols are tcp, udp, ah, esp, gre, igmp, and ipv6';
				$self->warn;
			}
			$protocols{$item} = 1;
		} ## end foreach my $item ( @{ $opts{protocols} } )
		my @protocols_keys = keys(%protocols);
		@protocols_keys = sort { $a cmp $b } @protocols_keys;
		push( @{ $self->{protocols} }, @protocols_keys );
	} ## end elsif ( defined( $opts{protocols} ) )

	# make sure prefix is sane if defiend
	if ( defined( $opts{prefix} ) && $opts{prefix} !~ /^[a-zA-Z0-9]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 6;
		$self->{errorString}
			= '"' . $opts{prefix} . '" is not a valid prefix as it does not match the regex /^[a-zA-Z0-9]+$/';
		$self->warn;
	} elsif ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	# make sure we have a name and that it is valid
	if ( !defined( $opts{name} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'name is undef';
		$self->warn;
	} elsif ( $opts{name} !~ /^[a-zA-Z0-9\-]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'name set to "' . $opts{name} . '" which does not match the regexp  /^[a-zA-Z0-9\-]+$/';
		$self->warn;
	}
	$self->{name} = $opts{name};

	# used internally for testing
	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}

	if ( defined( $opts{options} ) ) {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 8;
			$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
			$self->warn;
		}
		$self->{options} = $opts{options};

		if ( defined( $opts{options}{type} ) && ref( $opts{options}{type} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 20;
			$self->{errorString} = 'ref for $opts{options}{type} is "' . ref( $opts{options}{type} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{type} )
			&& $opts{options}{type} ne 'deny'
			&& $opts{options}{type} ne 'reject' )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "' . $opts{options}{type} . '" and not "deny" or "reject"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'deny';
		}

		if ( defined( $opts{options}{kill} )
			&& $opts{options}{kill} ne ''
			&& $opts{options}{kill} ne 'ss'
			&& $opts{options}{kill} ne 'conntrack' )
		{
			$self->{perror} = 1;
			$self->{error}  = 19;
			$self->{errorString}
				= '$opts{options}{kill} is "' . $opts{options}{kill} . '" and not "", "ss", or "conntrack"';
			$self->warn;
		} elsif ( !defined( $opts{options}{kill} ) ) {
			$self->{options}{kill} = '';
		}
	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

# Internal helper. Works out the protocol and port combinations this instance
# needs to block for the passed IP, and returns them as ufw rule
# specifications.
#
# This backend differs from the ipset based ones in a way that shapes
# everything here: ufw has no set or group concept, so there is nothing to add
# an address to. Rules are per address, which is why the IP is an argument
# rather than the specs being static and built once at init. Banning writes
# these rules and unbanning deletes them, so the count of rules on the host
# grows with the number of bans.
#
# There is no family split either. ufw works out the family from the address
# in the rule, so unlike the iptables and nftables backends there is no per
# family loop and no filtering of protocols that belong to the other family.
#
# Ports are only attached to tcp and udp, the only protocols ufw accepts a
# port specification for; anything else gets a protocol only rule.
#
# Args:
#
#     ip - The address to build the specifications for, as a plain string.
#          Expected to be an already validated and lowercased IPv4 or IPv6
#          address. It is interpolated into the rule as is.
#
# Returns the specifications as a list of strings, one per rule. Each is the
# portion of the rule after the deny or reject verb, so the caller prepends
# 'ufw deny ' or 'ufw delete deny ' to it. There is one entry per applicable
# protocol, so a single ban may produce several rules.
#
#     # no protocols and no ports: block everything from the address
#     $self->_rule_specs('10.0.0.1');
#     #   from 10.0.0.1 to any
#
#     # ports 22 with no protocols, so tcp and udp are assumed
#     $self->_rule_specs('10.0.0.1');
#     #   proto tcp from 10.0.0.1 to any port 22
#     #   proto udp from 10.0.0.1 to any port 22
#
#     # protocols tcp, ports 22 and 143
#     #   proto tcp from 10.0.0.1 to any port 22,143
#
#     # protocols gre, which takes no ports
#     #   proto gre from 10.0.0.1 to any
sub _rule_specs {
	my ( $self, $ip ) = @_;

	my @ports    = @{ $self->{ports} };
	my @protos   = @{ $self->{protocols} };
	my $port_str = join( ',', @ports );

	# protocols that accept a port specification under ufw
	my %port_ok = ( tcp => 1, udp => 1 );

	my @specs;
	if ( !@protos && !@ports ) {
		# block everything from the IP
		push( @specs, 'from ' . $ip . ' to any' );
	} elsif ( !@protos && @ports ) {
		# ports require a protocol, default to tcp and udp
		foreach my $proto ( 'tcp', 'udp' ) {
			push( @specs, 'proto ' . $proto . ' from ' . $ip . ' to any port ' . $port_str );
		}
	} else {
		foreach my $proto (@protos) {
			if ( @ports && $port_ok{$proto} ) {
				push( @specs, 'proto ' . $proto . ' from ' . $ip . ' to any port ' . $port_str );
			} else {
				push( @specs, 'proto ' . $proto . ' from ' . $ip . ' to any' );
			}
		}
	} ## end else [ if ( !@protos && !@ports ) ]

	return @specs;
} ## end sub _rule_specs

# Internal helper. Returns the commands that tear down the passed IP's
# existing connections, used when the kill option is on.
#
# This overrides the shared _kill_commands in
# Net::Firewall::BlockerHelper::Util, which the iptables, nftables, and
# firewalld backends inherit. It differs in two ways.
#
# First, it offers an ss based mode as well as the conntrack one, selected by
# the kill option. ss kills sockets directly rather than dropping conntrack
# entries, which is useful on a host where conntrack is not in play. ss can
# only kill TCP connections and connected UDP sockets, so its scoping is a
# choice between -t, -u, and -tu rather than a per protocol command; when
# neither TCP nor UDP is among the blocked protocols there is nothing it can
# do and no command is emitted at all. Note the address is bracketed
# unconditionally in the ss destination, which is the form ss accepts for both
# families.
#
# Second, the conntrack path here recognizes a much narrower protocol set,
# just tcp, udp, and gre, matching what ufw itself will write rules for. The
# shared version additionally handles sctp, dccp, udplite, and the ICMPs, none
# of which apply here, which is also why this version needs no ICMP family
# filtering and no duplicate suppression.
#
# Args:
#
#     ip - The address whose connections should be dropped, as a plain string.
#          Expected to be an already validated and lowercased IPv4 or IPv6
#          address. In conntrack mode the family is decided by matching
#          against $IPv4_re and controls the -f flag; in ss mode the address
#          is used as is.
#
# Returns the commands as a list of strings, ready to hand to the runner. The
# ss mode returns exactly one command, or none when neither TCP nor UDP is
# being blocked. The conntrack mode returns one entry per applicable protocol,
# or a single unscoped entry when nothing is configured, and may be empty if
# every configured protocol was filtered out.
#
#     # kill mode 'ss', nothing configured, so both TCP and UDP
#     $self->_kill_commands('10.0.0.1');
#     #   ss -K -tu dst "[10.0.0.1]"
#
#     # kill mode 'ss' with protocols tcp only
#     #   ss -K -t dst "[10.0.0.1]"
#
#     # kill mode 'ss' with protocols gre only: nothing ss can kill
#     $self->_kill_commands('10.0.0.1');    # ()
#
#     # conntrack mode, nothing configured
#     #   conntrack -D -s 10.0.0.1
#
#     # conntrack mode, IPv6, protocols tcp
#     #   conntrack -f ipv6 -D -p tcp -s 2001:db8::1
sub _kill_commands {
	my ( $self, $ip ) = @_;

	my @protos = @{ $self->{protocols} };
	if ( !@protos && defined( $self->{ports}[0] ) ) {
		# ports without protocols means tcp and udp are being blocked
		@protos = ( 'tcp', 'udp' );
	}

	if ( $self->{options}{kill} eq 'ss' ) {
		# scope to -t/-u per the blocked protocols; ss can only kill TCP
		# connections and connected UDP sockets, so if neither is being
		# blocked there is nothing applicable to kill
		my $flags = '-tu';
		if (@protos) {
			my $tcp = grep { $_ eq 'tcp' } @protos;
			my $udp = grep { $_ eq 'udp' } @protos;
			if ( $tcp && $udp ) {
				$flags = '-tu';
			} elsif ($tcp) {
				$flags = '-t';
			} elsif ($udp) {
				$flags = '-u';
			} else {
				return ();
			}
		} ## end if (@protos)
		return ( 'ss -K ' . $flags . ' dst "[' . $ip . ']"' );
	} ## end if ( $self->{options}{kill} eq 'ss' )

	# conntrack defaults to IPv4, so IPv6 IPs need the family specified
	my $is_v4  = ( $ip =~ /\A$IPv4_re\z/ ) ? 1 : 0;
	my $family = $is_v4 ? '' : '-f ipv6 ';

	# nothing configured means everything is being blocked, so drop every
	# entry for the IP
	if ( !@protos ) {
		return ( 'conntrack ' . $family . '-D -s ' . $ip );
	}

	# scope the kill to the blocked protocols; ones conntrack can not filter
	# by are skipped
	my %conntrack_protos = ( tcp => 'tcp', udp => 'udp', gre => 'gre' );

	my @commands;
	foreach my $proto (@protos) {
		my $conntrack_proto = $conntrack_protos{$proto};
		next if ( !defined($conntrack_proto) );
		push( @commands, 'conntrack ' . $family . '-D -p ' . $conntrack_proto . ' -s ' . $ip );
	}

	return @commands;
} ## end sub _kill_commands

# Internal helper. Returns the command used to confirm that ufw is actually
# enabled, which is this backend's health check.
#
# There is no container to look for here, no chain and no set, so unlike the
# other packet filter backends there is nothing whose presence would prove the
# setup is intact. What can go wrong instead is ufw being disabled out from
# under a running process, at which point every rule stops applying while ufw
# still happily accepts new ones. Checking the status is the closest
# equivalent, and it is what check and the self heal path use to decide
# whether a rebuild is needed.
#
# The grep is what turns the check into an exit status: ufw status always
# succeeds, and prints "Status: active" or "Status: inactive", so the state
# has to be read out of the output rather than the return code. Matching is
# anchored, case insensitive, and tolerant of the spacing.
#
# Takes no arguments.
#
# Returns the command as a single string ready to hand to the runner, a
# pipeline whose exit status is 0 when ufw is enabled and non zero when it is
# not.
#
#     $self->_status_command;
#     #   ufw status | grep -qiE "^Status:[[:space:]]*active"
sub _status_command {
	my ($self) = @_;

	return 'ufw status | grep -qiE "^Status:[[:space:]]*active"';
}

=head2 init

Initiates the backend. As there is no container to create, this just
verifies that ufw is enabled via C<ufw status>.

    $backend->init;

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my @commands = ( $self->_status_command );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = { commands => \@commands };
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 23;
				$self->{errorString}
					= 'init failed. ufw does not appear to be enabled... the command "'
					. $item
					. '" exited non-zero... output... '
					. $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then one C<< ufw prepend <type> ... >> rule per protocol is
added for it, based on the configured protocols and ports. If the C<kill>
option is set, existing connections/state for the IP are killed via C<ss -K>
or C<conntrack -D>. Banning an already banned IP is a noop.

    $backend->ban(ban => $ip);

=cut

sub ban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	my @commands;
	foreach my $spec ( $self->_rule_specs( $opts{ban} ) ) {
		push( @commands, 'ufw prepend ' . $self->{options}{type} . ' ' . $spec );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 13;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	if ( $self->{options}{kill} ) {
		foreach my $kill_command ( $self->_kill_commands( $opts{ban} ) ) {
			if ( $self->{testing} ) {
				push( @{ $self->{frontend_obj}->{test_data} }, $kill_command );
			} else {
				# best effort; exit codes are intentionally ignored as both
				# commands exit non-zero when there is nothing matching to kill
				my $output = `$kill_command 2>&1`;
			}
		}
	} ## end if ( $self->{options}{kill} )

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then its rules are removed via C<< ufw delete <type> ... >>,
one per protocol. Unbanning an IP that is not banned is a noop.

    $backend->unban(ban => $ip);

=cut

sub unban {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 10;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/
		&& $opts{ban} !~ /\A$IPv6_re\z/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	my @commands;
	foreach my $spec ( $self->_rule_specs( $opts{ban} ) ) {
		push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 14;
				$self->{errorString}
					= 'unban failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by prepending one or more per-range rules via
C<< ufw prepend <type> ... >>, one per protocol, in the same manner as a
single IP. The value of ban is validated as being a IPv4 or IPv6 CIDR range
and lowercased. Banning an already banned range is a noop.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( $self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	my @commands;
	foreach my $spec ( $self->_rule_specs( $opts{ban} ) ) {
		push( @commands, 'ufw prepend ' . $self->{options}{type} . ' ' . $spec );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 26;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by deleting its per-range rules via
C<< ufw delete <type> ... >>. The value of ban is validated as being a IPv4
or IPv6 CIDR range and lowercased. Unbanning a range that is not banned is
a noop.

    $backend->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	if ( !defined( $opts{ban} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = 'Nothing specified for the value ban';
		$self->warn;
		return;
	} elsif ( ref( $opts{ban} ) ne '' ) {
		$self->{error}       = 28;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 28;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 CIDR';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	if ( !$self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	my @commands;
	foreach my $spec ( $self->_rule_specs( $opts{ban} ) ) {
		push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 27;
				$self->{errorString}
					= 'unban failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges. Single IPs are not included; for those see L</list>.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list_cidr';
	}

	return keys( %{ $self->{banned_cidr} } );
}

=head2 list

List banned IPs. Returns an array of the currently banned single IPs. CIDR
ranges are not included; for those see L</list_cidr>.

    my @banned = $backend->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list';
	}

	return keys( %{ $self->{banned} } );
}

=head2 re_init

Tells the backend to re-init it's self.

This will call teardown and init again. After that it will
re-added all previously added bans.

    $backend->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	# both single IPs and CIDR ranges are re-added the same way
	my @to_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		foreach my $spec ( $self->_rule_specs($item) ) {
			my $command = 'ufw prepend ' . $self->{options}{type} . ' ' . $spec;

			if ( $self->{testing} ) {
				push( @re_init_test_data, $command );
			} else {
				my $output = `$command 2>&1`;
				if ( $? != 0 ) {
					$self->{error} = 13;
					$self->{errorString}
						= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
					$self->warn;
				}
			}
		} ## end foreach my $spec ( $self->_rule_specs($item) )
	} ## end foreach my $item (@to_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend by deleting the rules for all currently
banned IPs. The internal list of bans is kept, so a following re_init will
re-add them.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		foreach my $spec ( $self->_rule_specs($item) ) {
			push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
		}
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		foreach my $spec ( $self->_rule_specs($item) ) {
			push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
		}
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 17;
				$self->{errorString}
					= 'teardown failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]
} ## end sub teardown

=head2 stop

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $backend->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies that ufw is still enabled. Returns a true value if it is and a
false value otherwise. This is the equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my @commands = ( $self->_status_command );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
		return 1;
	}

	foreach my $item (@commands) {
		my $output = `$item 2>&1`;
		if ( $? != 0 ) {
			return 0;
		}
	}

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by deleting their rules and
forgetting them. This is the equivalent of fail2ban's C<actionflush>.

    $backend->flush;

=cut

sub flush {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		foreach my $spec ( $self->_rule_specs($item) ) {
			push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
		}
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		foreach my $spec ( $self->_rule_specs($item) ) {
			push( @commands, 'ufw delete ' . $self->{options}{type} . ' ' . $spec );
		}
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 25;
				$self->{errorString}
					= 'flush failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{banned}      = {};
	$self->{banned_cidr} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 2, invalidPortSpecified

Port is either not an int within the range 1 to 65535 or a name that can be resolved by getservbyname.

=head2 3, portsNotArray

The data passed to new for ports is not an array.

=head2 4, protocolsNotArray

The data passed to new for protocols is not an array.

=head2 5, invalidProtocolSpecified

The specified protocol could not be resolved via getprotobyname or is not
one understood by ufw.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP or CIDR range specified to ban or unban.

=head2 10, banItemNotIP

The item to ban is not an IP. Either wrong ref type or regexp
test using L<Regexp::IPv4> and L<Regexp::IPv6> failed.

=head2 12, backendInitError

Failed to init the backend.

=head2 13, banFailed

Failed to ban the item.

=head2 14, unbanFailed

Failed to unban the item.

=head2 15, listFailed

Failed to get a list of bans.

=head2 16, reInitFailed

Failed to re_init the backend.

=head2 17, teardownFailed

Failed to teardown the backend.

=head2 18, alreadyInited

init called, but the backend has already been inited.

=head2 19, killInvalid

The option kill is not '', 'ss', or 'conntrack'.

=head2 20, typeInvalid

The option type is not 'deny' or 'reject'.

=head2 23, initFailed

init failed. ufw does not appear to be enabled.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, banCidrFailed

Failed to ban the CIDR range.

=head2 27, unbanCidrFailed

Failed to unban the CIDR range.

=head2 28, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 29, cidrNotSupported

The backend does not support CIDR bans.

=head2 30, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
