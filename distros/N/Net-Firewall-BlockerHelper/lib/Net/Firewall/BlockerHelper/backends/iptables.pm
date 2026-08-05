package Net::Firewall::BlockerHelper::backends::iptables;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::iptables - iptables/ip6tables backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

Everything this backend needs is wired in by init itself, the jump from
C<INPUT> to its chain included, so no ruleset changes are needed
beforehand. The jump is appended to the end of C<INPUT> though, and
iptables is first match wins, so any earlier rule accepting the traffic in
question, such as a blanket ACCEPT for a port or an established/related
state rule, will win out over the bans. If bans appear to have no effect,
check where the jump to C<< <prefix>_<name> >> sits via
C<iptables -L INPUT> and relocate it above such rules; the backend finds
it by rule spec rather than position, so moving it is safe.

    use Net::Firewall::BlockerHelper::backends::iptables;

    my $backend1;
    my $backend2;
    eval {
        $backend1 = Net::Firewall::BlockerHelper::backends::iptables->new(
                name => 'all',
                options=>{ kill=>1 },
            );
        $backend2 = Net::Firewall::BlockerHelper::backends::iptables->new(
                ports => ['143'],
                protocols => ['tcp'],
                name => 'imap',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

    $backend1->init;
    $backend2->init;

    $backend1->ban(ban=>'1.2.3.4');
    $backend1->ban(ban=>'4.3.2.1');
    $backend2->ban(ban=>'4.3.2.1');

    use Data::Dumper;
    print Dumper($backend1->list);
    print Dumper($backend2->list);

    $backend1->unban(ban=>'4.3.2.1');

    $backend1->teardown;
    $backend2->teardown;

=head1 DESCRIPTION

This backend blocks IPs using L<ipset(8)> in combination with
L<iptables(8)> and L<ip6tables(8)>.

For each instance two ipsets are created, one for IPv4
(C<< <prefix>_<name>_4 >>) and one for IPv6 (C<< <prefix>_<name>_6 >>),
along with a dedicated chain (C<< <prefix>_<name> >>) in each of the
C<filter> tables. The chain is populated with the block rules and jumped
to from C<INPUT>. Banning an IP is then simply a matter of adding it to
the relevant ipset.

When the C<tarpit> or C<delude> type is used a same-named chain is also
created in the C<raw> table and jumped to from C<PREROUTING>, holding
C<< -j CT --notrack >> rules that match the same traffic. This exempts the
tarpitted/deluded connections from connection tracking, which those
xtables-addons targets require to work. It is created and removed
automatically with the filter chain.

Requires C<ipset>, C<iptables>, and C<ip6tables> to be installed and in
the C<PATH> of the process, which must have sufficient privileges to run
them. The C<tarpit>/C<delude> types additionally require the C<TARPIT>/
C<DELUDE> targets from xtables-addons.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for furhter info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are positive ints or a valid
            service name via getservbyname. All ports will be blocked if non are specified. If
            duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. By default will block all,
            unless ports are given, in which case it defaults to tcp and udp. This
            is checked against /etc/protocols via the function getprotobyname. Duplicates
            will be discarded.
        - Default :: [], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - type :: The block method to use. One of 'drop', 'reject', 'tarpit',
            or 'delude'.
                - drop   :: Silently drop the packet. See iptables(8).
                - reject :: Send an ICMP port-unreachable back. See iptables(8).
                - tarpit :: Hold the TCP connection open with a zero window so
                        the attacker wastes resources. Requires the TARPIT
                        target from xtables-addons. TCP only.
                - delude :: Answer a SYN with a SYN/ACK and everything else with
                        a RST, so the port looks open but never completes a
                        session. Requires the DELUDE target from xtables-addons.
                        TCP only. The target itself is also IPv4 only, as
                        xtables-addons provides no IPv6 version, so the IPv6
                        rule falls back to DROP; banned IPv6 IPs are still
                        blocked, just silently dropped rather than deluded.
            The tarpit and delude types only ever emit '-p tcp' rules; any
            non-tcp protocol or port default (eg the implicit udp) is skipped
            rather than handed to a target the kernel would reject. For these
            types the backend also installs a matching '-j CT --notrack' rule
            in a raw table chain jumped from PREROUTING, so conntrack does not
            process (and fight) the crafted replies; this is set up and torn
            down automatically alongside the filter chain.
        - Default :: drop

    - tarpit_mode :: When type is 'tarpit', selects the TARPIT mode, one of
            'tarpit' (default, zero-window hold), 'honeypot' (accept then hold),
            or 'reset'. Ignored for the other types.
        - Default :: tarpit

    - kill :: Use conntrack(8) to drop existing connection tracking entries
            for the banned IP, for both IPv4 and IPv6. When protocols are
            configured the kill is scoped to them via -p, so blocking only
            udp will not drop tcp entries and vice versa; protocols conntrack
            can not filter by are skipped. With no protocols configured
            everything is being blocked, so entries of every protocol are
            dropped.
        - Default :: 0

All errors are considered fatal, meaning if new fails it will die.

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::iptables->new(
                ports => ['22'],
                protocols => ['tcp'],
                name => 'ssh',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

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
				5  => 'invalidPortSpecified',
				6  => 'invalidPrefixSpecified',
				7  => 'invalidName',
				8  => 'optionsNotHash',
				9  => 'noBanItem',
				10 => 'banItemNotIP',
				11 => 'invalidBackend',
				12 => 'backendInitError',
				13 => 'banFailed',
				14 => 'unbanFailed',
				15 => 'listFailed',
				16 => 'reInitFailed',
				17 => 'teardownFailed',
				18 => 'alreadyInited',
				20 => 'typeInvalid',
				21 => 'nameTooLong',
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
			type => 'drop',
			kill => 0,
		},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
		cidr_supported => 0,
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
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 ) ]
		} ## end foreach my $item ( @{ $opts{ports} } )
		my @port_keys = keys(%ports);
		@port_keys = sort { $a <=> $b } @port_keys;
		push( @{ $self->{ports} }, @port_keys );
	} ## end elsif ( defined( $opts{ports} ) )

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

	# iptables limits chain names to 28 characters and ipset set names to 31;
	# the chain is <prefix>_<name> and the sets are <prefix>_<name>_4/_6, so
	# catch over-long combos here rather than as a confusing error at init
	if ( defined( $self->{name} ) && length( $self->{prefix} . '_' . $self->{name} ) > 28 ) {
		$self->{perror} = 1;
		$self->{error}  = 21;
		$self->{errorString}
			= 'the combined prefix and name, "'
			. $self->{prefix} . '_'
			. $self->{name}
			. '", is longer than 28 characters, the max iptables chain name length';
		$self->warn;
	}

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

		if ( !defined( $opts{options}{kill} ) ) {
			$self->{options}{kill} = 0;
		}

		# tarpit and delude are xtables-addons targets, hence not lumped in
		# with the base drop/reject that plain iptables always provides
		my %valid_types = ( drop => 1, reject => 1, tarpit => 1, delude => 1 );

		if ( defined( $opts{options}{type} ) && ref( $opts{options}{type} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 20;
			$self->{errorString} = 'ref for $opts{options}{type} is "' . ref( $opts{options}{type} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{type} )
			&& !$valid_types{ $opts{options}{type} } )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "'
				. $opts{options}{type}
				. '" and not one of "drop", "reject", "tarpit", or "delude"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'drop';
		}

		# tarpit has three modes; delude and the plain targets take none. Only
		# validate it here, _rule_commands decides when it is actually emitted.
		my %valid_tarpit_modes = ( tarpit => 1, honeypot => 1, reset => 1 );
		if ( defined( $opts{options}{tarpit_mode} )
			&& ( ref( $opts{options}{tarpit_mode} ) ne ''
				|| !$valid_tarpit_modes{ $opts{options}{tarpit_mode} } ) )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{tarpit_mode} is "'
				. ( ref( $opts{options}{tarpit_mode} ) ne '' ? ref( $opts{options}{tarpit_mode} ) : $opts{options}{tarpit_mode} )
				. '" and not one of "tarpit", "honeypot", or "reset"';
			$self->warn;
		}

	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

# Internal helper. Returns the IPv4 ipset name, IPv6 ipset name, and chain
# name for this instance.
sub _set_names {
	my ($self) = @_;

	my $chain = $self->{prefix} . '_' . $self->{name};
	return ( $chain . '_4', $chain . '_6', $chain );
}

# Internal helper. True when the configured type is one of the xtables-addons
# TCP targets (tarpit/delude) that require the matching traffic to be exempted
# from connection tracking. See _notrack_commands.
sub _needs_notrack {
	my ($self) = @_;

	my $type = $self->{options}{type};
	return ( $type eq 'tarpit' || $type eq 'delude' ) ? 1 : 0;
}

# Internal helper. Returns the list of per-rule specs the block rules are built
# from, as hashrefs of { fam => \%family, match => $match } where
# match is the portion of the rule between src and -j (eg
# ' -p tcp -m multiport --dports 22', or '' for match-everything).
#
# Both _rule_commands (the filter table block rules) and
# _notrack_commands (the raw table conntrack exemptions) are generated from
# these specs so the two always match exactly the same traffic.
sub _rule_specs {
	my ($self) = @_;

	my ( $set4, $set6 ) = $self->_set_names;

	my @ports    = @{ $self->{ports} };
	my @protos   = @{ $self->{protocols} };
	my $port_str = join( ',', @ports );

	my $type = $self->{options}{type};

	# work out the target for each family
	my $t4 = 'DROP';
	my $t6 = 'DROP';
	if ( $type eq 'reject' ) {
		$t4 = 'REJECT --reject-with icmp-port-unreachable';
		$t6 = 'REJECT --reject-with icmp6-port-unreachable';
	} elsif ( $type eq 'tarpit' ) {
		# xtables-addons TARPIT; --honeypot/--reset select the alternate modes,
		# the default --tarpit is left implicit so older builds still accept it
		my $mode = $self->{options}{tarpit_mode};
		$t4 = ( defined($mode) && $mode ne 'tarpit' ) ? 'TARPIT --' . $mode : 'TARPIT';
		$t6 = $t4;
	} elsif ( $type eq 'delude' ) {
		$t4 = 'DELUDE';
		# xtables-addons provides no IPv6 DELUDE, so v6 falls back to DROP;
		# banned IPv6 IPs are still blocked, just not deluded
		$t6 = 'DROP';
	}

	# TARPIT and DELUDE only handle TCP, so their rules are forced to -p tcp
	# and any non-tcp protocol/port combination is skipped rather than emitted
	# with a target the kernel would reject.
	my $tcp_only = $self->_needs_notrack;

	my @families = (
		{ cmd => 'iptables',  set => $set4, tgt => $t4, family => 4 },
		{ cmd => 'ip6tables', set => $set6, tgt => $t6, family => 6 },
	);

	# protocols that accept a port specification
	my %port_ok = ( tcp => 1, udp => 1, sctp => 1 );

	# the various names the IPv6 ICMP protocol may go by
	my %v6_icmp = ( 'ipv6-icmp' => 1, 'icmp6' => 1, 'icmpv6' => 1 );

	my @specs;
	foreach my $fam (@families) {
		if ( !@protos && !@ports ) {
			if ($tcp_only) {
				# tarpit/delude have no all-protocol form; scope to tcp
				push( @specs, { fam => $fam, match => ' -p tcp' } );
			} else {
				# block everything sourced from the set
				push( @specs, { fam => $fam, match => '' } );
			}
		} elsif ( !@protos && @ports ) {
			# ports require a protocol, default to tcp and udp, but tarpit/delude
			# are tcp only so udp is dropped from that default
			my @default_protos = $tcp_only ? ('tcp') : ( 'tcp', 'udp' );
			foreach my $proto (@default_protos) {
				push( @specs, { fam => $fam, match => ' -p ' . $proto . ' -m multiport --dports ' . $port_str } );
			}
		} else {
			foreach my $proto (@protos) {
				# skip protocols that do not belong to this family
				if ( $fam->{family} == 6 ) {
					next if ( $proto eq 'icmp' );
				} else {
					next if ( $v6_icmp{$proto} );
				}

				# tarpit/delude can only target tcp, so leave the rest untouched
				next if ( $tcp_only && $proto ne 'tcp' );

				my $match = ' -p ' . $proto;
				if ( @ports && $port_ok{$proto} ) {
					$match .= ' -m multiport --dports ' . $port_str;
				}
				push( @specs, { fam => $fam, match => $match } );
			} ## end foreach my $proto (@protos)
		} ## end else [ if ( !@protos && !@ports ) ]
	} ## end foreach my $fam (@families)

	return @specs;
} ## end sub _rule_specs

# Internal helper. Returns the list of commands that populate the filter chain
# with the block rules, based on the configured protocols and ports.
sub _rule_commands {
	my ($self) = @_;

	my ( undef, undef, $chain ) = $self->_set_names;

	my @commands;
	foreach my $spec ( $self->_rule_specs ) {
		my $fam = $spec->{fam};
		push( @commands,
			      $fam->{cmd}
				. ' -A '
				. $chain
				. ' -m set --match-set '
				. $fam->{set} . ' src'
				. $spec->{match} . ' -j '
				. $fam->{tgt} );
	}

	return @commands;
} ## end sub _rule_commands

# Internal helper. Returns the raw table rules that exempt the tarpitted or
# deluded traffic from connection tracking, or an empty list for the plain
# drop/reject types that do not need it.
#
# TARPIT and DELUDE craft their own TCP replies (a zero-window ACK stream and a
# SYN/ACK-then-RST respectively) with no local socket. If conntrack tracks that
# traffic the kernel's own stack also processes it, which both undoes the trick
# and pins an INVALID conntrack entry per attacker packet. Adding a
# -j CT --notrack rule in raw/PREROUTING that matches exactly the same
# source set, protocol, and ports as the block rule keeps conntrack out of the
# way. These populate a same-named chain in the raw table (chain names are
# per-table, so it does not collide with the filter chain).
sub _notrack_commands {
	my ($self) = @_;

	return () if ( !$self->_needs_notrack );

	my ( undef, undef, $chain ) = $self->_set_names;

	my @commands;
	foreach my $spec ( $self->_rule_specs ) {
		my $fam = $spec->{fam};

		# only the traffic actually handled by a reply-crafting target needs
		# exempting from conntrack; the v6 DROP fallback delude uses does not
		next if ( $fam->{tgt} !~ /^(TARPIT|DELUDE)/ );

		push( @commands,
			      $fam->{cmd}
				. ' -t raw -A '
				. $chain
				. ' -m set --match-set '
				. $fam->{set} . ' src'
				. $spec->{match}
				. ' -j CT --notrack' );
	}

	return @commands;
} ## end sub _notrack_commands

# Internal helper. Returns the commands that create the raw table chain, fill
# it with the _notrack_commands, and jump to it from raw/PREROUTING. Empty
# unless the type needs notrack.
sub _raw_setup_commands {
	my ($self) = @_;

	return () if ( !$self->_needs_notrack );

	my ( undef, undef, $chain ) = $self->_set_names;

	return (
		'iptables -t raw -N ' . $chain,
		'ip6tables -t raw -N ' . $chain,
		$self->_notrack_commands,
		'iptables -t raw -A PREROUTING -j ' . $chain,
		'ip6tables -t raw -A PREROUTING -j ' . $chain,
	);
} ## end sub _raw_setup_commands

# Internal helper. Returns the commands that remove the raw table chain and its
# jump from raw/PREROUTING. Empty unless the type needs notrack.
sub _raw_teardown_commands {
	my ($self) = @_;

	return () if ( !$self->_needs_notrack );

	my ( undef, undef, $chain ) = $self->_set_names;

	return (
		'iptables -t raw -D PREROUTING -j ' . $chain,
		'ip6tables -t raw -D PREROUTING -j ' . $chain,
		'iptables -t raw -F ' . $chain,
		'ip6tables -t raw -F ' . $chain,
		'iptables -t raw -X ' . $chain,
		'ip6tables -t raw -X ' . $chain,
	);
} ## end sub _raw_teardown_commands

# Internal helper. Returns the conntrack commands used to drop existing
# connection tracking entries for the passed IP. When protocols are
# configured, the kill is scoped to them via -p so protocols that are not
# being blocked are left alone; otherwise every entry for the IP is dropped.
sub _kill_commands {
	my ( $self, $ip ) = @_;

	# conntrack defaults to IPv4, so IPv6 IPs need the family specified
	my $is_v4  = ( $ip =~ /\A$IPv4_re\z/ ) ? 1 : 0;
	my $family = $is_v4 ? '' : '-f ipv6 ';

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

=head2 init

Initiates the backend. Creates the two ipsets, C<< <prefix>_<name>_4 >>
(hash:ip family inet) and C<< <prefix>_<name>_6 >> (hash:ip family inet6),
creates the C<< <prefix>_<name> >> chain via C<iptables -N> and
C<ip6tables -N>, populates it with the block rules built from the configured
type, protocols, and ports, and appends a jump to it from C<INPUT>. For the
tarpit and delude types a same-named chain holding the C<-j CT --notrack>
rules is also created in the C<raw> table and jumped to from C<PREROUTING>.

Note that the jump is appended to the end of C<INPUT>, so earlier rules
accepting the traffic win out over the bans. See L</SYNOPSIS>.

Before any of that, matching stale chains and ipsets from a previous run are
removed; those cleanup commands are allowed to fail.

No arguments are taken.

If called a second time without an intervening teardown, it will error.

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

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = {};
	}

	my ( $set4, $set6, $chain ) = $self->_set_names;

	# these are cleanup commands for any stale state and are allowed to fail
	my @fail_okay_commands;
	push( @fail_okay_commands, 'iptables -D INPUT -j ' . $chain );
	push( @fail_okay_commands, 'ip6tables -D INPUT -j ' . $chain );
	push( @fail_okay_commands, 'iptables -F ' . $chain );
	push( @fail_okay_commands, 'ip6tables -F ' . $chain );
	push( @fail_okay_commands, 'iptables -X ' . $chain );
	push( @fail_okay_commands, 'ip6tables -X ' . $chain );

	# the stale raw table notrack chain (tarpit/delude only; empty otherwise)
	# has to go before the ipset destroys, as its rules reference the sets
	# and a referenced set can not be destroyed
	push( @fail_okay_commands, $self->_raw_teardown_commands );

	push( @fail_okay_commands, 'ipset destroy ' . $set4 );
	push( @fail_okay_commands, 'ipset destroy ' . $set6 );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{fail_okay_commands} = \@fail_okay_commands;
	} else {
		foreach my $item (@fail_okay_commands) {
			my $output = `$item 2>&1`;
		}
	}

	my @commands;
	# create the ipsets and the chain
	push( @commands, 'ipset create ' . $set4 . ' hash:ip family inet' );
	push( @commands, 'ipset create ' . $set6 . ' hash:ip family inet6' );
	push( @commands, 'iptables -N ' . $chain );
	push( @commands, 'ip6tables -N ' . $chain );

	# add the block rules to the chain
	push( @commands, $self->_rule_commands );

	# jump to the chain from INPUT
	push( @commands, 'iptables -A INPUT -j ' . $chain );
	push( @commands, 'ip6tables -A INPUT -j ' . $chain );

	# for tarpit/delude, exempt the matching traffic from conntrack via a raw
	# table chain; empty for the plain drop/reject types
	push( @commands, $self->_raw_setup_commands );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{commands} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 23;
				$self->{errorString}
					= 'init failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the instance's IPv4 or IPv6 ipset, as
appropriate for its family, via C<ipset add>. Banning an already banned IP
is a noop.

If the C<kill> option is set, L<conntrack(8)> is then used to drop existing
connection tracking entries for the IP; its exit code is ignored, as it is
non-zero when there is nothing to delete.

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

	my ( $set4, $set6 ) = $self->_set_names;
	my $set = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;

	my $command = 'ipset add ' . $set . ' ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 13;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	if ( $self->{options}{kill} ) {
		foreach my $kill_command ( $self->_kill_commands( $opts{ban} ) ) {
			if ( $self->{testing} ) {
				push( @{ $self->{frontend_obj}->{test_data} }, $kill_command );
			} else {
				# conntrack returns non-zero when there is nothing to delete,
				# so its exit code is intentionally ignored
				my $output = `$kill_command 2>&1`;
			}
		}
	} ## end if ( $self->{options}{kill} )

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the instance's IPv4 or IPv6 ipset, as
appropriate for its family, via C<ipset del>. Unbanning an IP that is not
banned is a noop.

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

	my ( $set4, $set6 ) = $self->_set_names;
	my $set = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;

	my $command = 'ipset del ' . $set . ' ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 14;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 list

List banned IPs. Returns an array of the currently banned IPs from the
retained ban state; the ipsets themselves are not queried.

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

Calls teardown, with any errors from it ignored as a partially wiped setup
is exactly what re_init exists to recover from, then init, recreating the
ipsets, chain, and rules. Each previously banned IP is then re-added to the
relevant ipset via C<ipset add>.

    $backend->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my ( $set4, $set6 ) = $self->_set_names;

	my @to_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $set = ( $item =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;
		my $command = 'ipset add ' . $set . ' ' . $item;

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
	} ## end foreach my $item (@to_ban)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

Removes the jump from C<INPUT>, flushes and deletes the chain, and destroys
both ipsets, via C<iptables>, C<ip6tables>, and C<ipset destroy>. For the
tarpit and delude types the raw table chain and its C<PREROUTING> jump are
removed as well, before the ipsets its rules reference are destroyed. The
retained ban state is kept, so a later init/re_init can restore the bans.

It does not check if the backend has been inited, so if called prior to
init the removal commands will fail and it will error.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my ( $set4, $set6, $chain ) = $self->_set_names;

	my @commands;
	push( @commands, 'iptables -D INPUT -j ' . $chain );
	push( @commands, 'ip6tables -D INPUT -j ' . $chain );
	push( @commands, 'iptables -F ' . $chain );
	push( @commands, 'ip6tables -F ' . $chain );
	push( @commands, 'iptables -X ' . $chain );
	push( @commands, 'ip6tables -X ' . $chain );

	# remove the raw notrack chain (tarpit/delude only) before destroying the
	# ipsets, as its rules reference them; empty otherwise
	push( @commands, $self->_raw_teardown_commands );

	push( @commands, 'ipset destroy ' . $set4 );
	push( @commands, 'ipset destroy ' . $set6 );

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

Verifies that the ipsets, the chain jump, and each of the block rules in the
chain are still in place. Returns a true value if the setup is intact and a
false value if any part is missing. This is the equivalent of fail2ban's
C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my ( $set4, $set6, $chain ) = $self->_set_names;

	# reuse the -A commands that populate the chains as -C existence checks, so
	# every block rule (and, for tarpit/delude, every raw notrack rule) the
	# setup should contain is verified
	my @rule_checks = ( $self->_rule_commands, $self->_notrack_commands );
	foreach my $item (@rule_checks) {
		$item =~ s/ -A / -C /;
	}

	my @commands = (
		'ipset list ' . $set4,
		'ipset list ' . $set6,
		'iptables -C INPUT -j ' . $chain,
		'ip6tables -C INPUT -j ' . $chain,
		@rule_checks,
	);

	# the raw table jump only exists for tarpit/delude; empty otherwise
	if ( $self->_needs_notrack ) {
		push( @commands, 'iptables -t raw -C PREROUTING -j ' . $chain );
		push( @commands, 'ip6tables -t raw -C PREROUTING -j ' . $chain );
	}

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

Removes all currently banned IPs at once by flushing the ipsets, leaving the
chain and rules in place. This is the equivalent of fail2ban's
C<actionflush>.

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

	my ( $set4, $set6 ) = $self->_set_names;

	my @commands = ( 'ipset flush ' . $set4, 'ipset flush ' . $set6 );

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

	$self->{banned} = {};
} ## end sub flush

# Internal helper. Returns a true value if the passed scalar is a valid IPv4 or
# IPv6 CIDR range, that is an address followed by "/" and a prefix length that
# is within the range valid for its family (0 to 32 for IPv4, 0 to 128 for
# IPv6). Returns false otherwise.
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

=head2 ban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 29;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub ban_cidr

=head2 unban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 29;
	$self->{errorString} = 'the ' . __PACKAGE__ . ' backend does not support CIDR bans';
	$self->warn;

	return;
} ## end sub unban_cidr

=head2 list_cidr

CIDR bans are not supported by this backend, so this always returns an empty
list.

    my @banned_cidrs = $backend->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return ();
}

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

=head2 5, invalidPortSpecified

Port is either not an int within the range 1 to 65535 or a name that can be resolved by getservbyname.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP specified to ban or unban.

=head2 10, banItemNotIP

The item to ban is not an IP. Either wrong ref type or regexp
test using L<Regexp::IPv4> and L<Regexp::IPv6> failed.

=head2 11, invalidBackend

The specified backend failed to pass a basic sanity check of making sure it
matches the regexp /^[a-zA-Z0-9\_]+$/.

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

=head2 20, typeInvalid

The option type is not one of "drop", "reject", "tarpit", or "delude", or the
option tarpit_mode is not one of "tarpit", "honeypot", or "reset".

=head2 21, nameTooLong

The combined prefix and name is longer than 28 characters, the max iptables
chain name length.

=head2 23, initFailed

One of the required commands for init failed.

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

1;    # End of Net::Firewall::BlockerHelper
