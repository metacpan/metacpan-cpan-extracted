package Net::Firewall::BlockerHelper::backends::nftables;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::nftables - nftables backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'nftables',
            ports => ['22'],
            protocols => ['tcp'],
            name => 'ssh',
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => 'dead::1');
    $fw_helper->unban(ban => '1.2.3.4');
    $fw_helper->teardown;

=head1 DESCRIPTION

Blocks IPs using L<nft(8)>.

A dedicated table C<< inet <prefix>_<name> >> is created per instance,
containing a base chain hooked to input, one set for IPv4
(C<< <prefix>_<name>_4 >>) and one for IPv6 (C<< <prefix>_<name>_6 >>), and
the block rules referencing them. Banning an IP adds it to the relevant set.
As the whole setup lives in its own table, teardown is simply deleting the
table.

Requires C<nft> to be installed and in the C<PATH> of the process, which must
have sufficient privileges to run it.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for furhter info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are ints within the
            range 1 to 65535 or a valid service name via getservbyname. All ports will be
            blocked if non are specified. Duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. This is checked against
            /etc/protocols via the function getprotobyname. Duplicates will be
            discarded. If no protocols are given, all IPv4 and IPv6 traffic
            sourced from the sets is blocked, unless ports are given, in which
            case it defaults to tcp and udp. Ports are only attached to
            port-capable protocols (tcp/udp/sctp); other protocols are blocked
            without a port.
        - Default :: [], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - type :: The drop method to use. 'drop' silently drops. 'reject' sends
            the family-appropriate ICMP port-unreachable back.
        - Default :: drop

    - priority :: Priority of the base chain. See nft(8).
        - Default :: -1

    - kill :: Use conntrack(8) to drop existing connection tracking entries
            for the banned IP, for both IPv4 and IPv6. When protocols are
            configured the kill is scoped to them via -p, so blocking only
            udp will not drop tcp entries and vice versa; protocols conntrack
            can not filter by are skipped. With no protocols configured
            everything is being blocked, so entries of every protocol are
            dropped.
        - Default :: 0

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
				5  => 'invalidPortSpecified',
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
				19 => 'priorityInvalid',
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
			type     => 'drop',
			priority => -1,
			kill     => 0,
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
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 &&...)]
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
			&& $opts{options}{type} ne 'drop'
			&& $opts{options}{type} ne 'reject' )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "' . $opts{options}{type} . '" and not "drop" or "reject"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'drop';
		}

		if ( !defined( $opts{options}{kill} ) ) {
			$self->{options}{kill} = 0;
		}

		if ( defined( $opts{options}{priority} ) && $opts{options}{priority} !~ /^\-?[0-9]+$/ ) {
			$self->{perror} = 1;
			$self->{error}  = 19;
			$self->{errorString}
				= '$opts{options}{priority} is "' . $opts{options}{priority} . '" and not an int';
			$self->warn;
		} elsif ( !defined( $opts{options}{priority} ) ) {
			$self->{options}{priority} = -1;
		}
	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

# Internal helper. Returns the three nftables object names this instance owns:
# its table, which is also the name of the chain inside it, and its two sets.
#
# All three are derived from the prefix and the name rather than stored, so
# every part of the backend agrees on what to create, reference, and tear down
# without threading the names around. The prefix and name pair is unique per
# instance, so two instances can share a host without colliding.
#
# The table and the chain deliberately share one name. nftables scopes chain
# names to their table, so there is no collision, and having the instance own
# a whole inet table means teardown can delete the table and take the chain,
# both sets, and every rule with it in one command.
#
# There are still two sets despite the table being inet and therefore holding
# both families, because an nftables set is typed: one is ipv4_addr and the
# other ipv6_addr, and neither will hold the other's addresses.
#
# Takes no arguments.
#
# Returns a three element list of the table name, the IPv4 set name, and the
# IPv6 set name, in that order. Note this differs from the iptables backend's
# _set_names, which returns the sets first and the chain last.
#
#     my ( $table, $set4, $set6 ) = $self->_names;
#
#     # with prefix "kur" and name "ssh"
#     #   $table is 'kur_ssh'   -- and the chain inside it is also 'kur_ssh'
#     #   $set4  is 'kur_ssh_4'
#     #   $set6  is 'kur_ssh_6'
sub _names {
	my ($self) = @_;

	my $table = $self->{prefix} . '_' . $self->{name};
	return ( $table, $table . '_4', $table . '_6' );
}

# Internal helper. Works out the full cross product of family, protocol, and
# ports this instance needs to block and returns it as nftables rule
# statements, along with a record of which sets those statements actually
# mention. Essentially all of the backend's rule logic lives here.
#
# The second return value exists for check. Verifying the setup is still
# intact means confirming the sets the rules depend on are present, and which
# sets those are is not always both of them: a configuration whose protocols
# are all one family, say icmp only, produces rules referencing just the IPv4
# set, and demanding the IPv6 set exist would then report a healthy setup as
# broken. Rather than have check re-derive that, it is recorded here where the
# decision is actually made.
#
# Protocols belonging to the wrong family are skipped, so icmp never lands in
# an ip6 rule and the various spellings of IPv6 ICMP never land in an ip one.
# Ports are only attached to protocols that have them; anything else is
# matched with meta l4proto, which is how nftables matches a protocol it has
# no dedicated keyword for.
#
# Unlike the iptables backend there is no tarpit or delude here, so the target
# is just drop or reject and does not vary by family.
#
# Takes no arguments; family, protocols, ports, and type all come from the
# object.
#
# Returns a two element list:
#
#     - an arrayref of rule statement strings, each the complete body of one
#       nft rule, ready to have "nft add rule inet <table> <chain> " put in
#       front of it
#     - a hashref keyed by the set names those statements reference, values
#       all 1, for check to confirm
#
#     my ( $specs, $referenced ) = $self->_rule_specs;
#
#     # no protocols and no ports, type drop
#     #   $specs is [ 'ip saddr @kur_ssh_4 drop', 'ip6 saddr @kur_ssh_6 drop' ]
#     #   $referenced is { kur_ssh_4 => 1, kur_ssh_6 => 1 }
#
#     # ports 22 with no protocols: defaults to tcp and udp per family
#     #   'tcp dport { 22 } ip saddr @kur_ssh_4 drop'
#     #   'udp dport { 22 } ip saddr @kur_ssh_4 drop'
#     #   'tcp dport { 22 } ip6 saddr @kur_ssh_6 drop'
#     #   'udp dport { 22 } ip6 saddr @kur_ssh_6 drop'
#
#     # protocols gre, which takes no ports
#     #   'meta l4proto gre ip saddr @kur_ssh_4 drop'
#     #   'meta l4proto gre ip6 saddr @kur_ssh_6 drop'
sub _rule_specs {
	my ($self) = @_;

	my ( $table, $set4, $set6 ) = $self->_names;

	my @ports    = @{ $self->{ports} };
	my @protos   = @{ $self->{protocols} };
	my $port_str = join( ', ', @ports );

	my $target = $self->{options}{type} eq 'reject' ? 'reject' : 'drop';

	# protocols that accept a port specification
	my %port_ok = ( tcp => 1, udp => 1, sctp => 1 );

	# the various names the IPv6 ICMP protocol may go by
	my %v6_icmp = ( 'ipv6-icmp' => 1, 'icmp6' => 1, 'icmpv6' => 1 );

	my @families = (
		{ set => $set4, saddr => 'ip',  family => 4 },
		{ set => $set6, saddr => 'ip6', family => 6 },
	);

	my @specs;
	my %referenced;
	foreach my $fam (@families) {
		my $match = $fam->{saddr} . ' saddr @' . $fam->{set};

		if ( !@protos && !@ports ) {
			# block everything sourced from the set
			push( @specs, $match . ' ' . $target );
			$referenced{ $fam->{set} } = 1;
		} elsif ( !@protos && @ports ) {
			# ports require a protocol, default to tcp and udp
			foreach my $proto ( 'tcp', 'udp' ) {
				push( @specs, $proto . ' dport { ' . $port_str . ' } ' . $match . ' ' . $target );
				$referenced{ $fam->{set} } = 1;
			}
		} else {
			foreach my $proto (@protos) {
				# skip protocols that do not belong to this family
				if ( $fam->{family} == 6 ) {
					next if ( $proto eq 'icmp' );
				} else {
					next if ( $v6_icmp{$proto} );
				}

				if ( @ports && $port_ok{$proto} ) {
					push( @specs, $proto . ' dport { ' . $port_str . ' } ' . $match . ' ' . $target );
				} else {
					push( @specs, 'meta l4proto ' . $proto . ' ' . $match . ' ' . $target );
				}
				$referenced{ $fam->{set} } = 1;
			} ## end foreach my $proto (@protos)
		} ## end else [ if ( !@protos && !@ports ) ]
	} ## end foreach my $fam (@families)

	return ( \@specs, \%referenced );
} ## end sub _rule_specs

=head2 init

Initiates the backend. First a best effort C<nft delete table> is run to
clear any stale copy of the table, then the table
C<< inet <prefix>_<name> >>, a base chain of the same name hooked to input
at the configured priority, the IPv4 set (C<< <prefix>_<name>_4 >>), the
IPv6 set (C<< <prefix>_<name>_6 >>), and the block rules referencing the
sets are created via C<nft add>. A failure of any of the creation commands
raises an error.

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

	my ( $table, $set4, $set6 ) = $self->_names;

	# stale state cleanup, allowed to fail
	my @fail_okay_commands = ( "nft 'delete table inet " . $table . "'" );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{fail_okay_commands} = \@fail_okay_commands;
	} else {
		foreach my $item (@fail_okay_commands) {
			my $output = `$item 2>&1`;
		}
	}

	my ($specs) = $self->_rule_specs;

	my @commands;
	push( @commands, "nft 'add table inet " . $table . "'" );
	push( @commands,
			  "nft 'add chain inet "
			. $table . ' '
			. $table
			. ' { type filter hook input priority '
			. $self->{options}{priority}
			. " ; policy accept ; }'" );
	push( @commands, "nft 'add set inet " . $table . ' ' . $set4 . " { type ipv4_addr; }'" );
	push( @commands, "nft 'add set inet " . $table . ' ' . $set6 . " { type ipv6_addr; }'" );
	foreach my $spec ( @{$specs} ) {
		push( @commands, "nft 'add rule inet " . $table . ' ' . $table . ' ' . $spec . "'" );
	}

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
and lowercased, then added to the family-appropriate set via
C<nft add element>. If the C<kill> option is set, conntrack(8) is then used
to drop existing connection tracking entries for the IP. Banning an already
banned IP is a noop.

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

	my ( $table, $set4, $set6 ) = $self->_names;
	my $set = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;

	my $command = "nft 'add element inet " . $table . ' ' . $set . ' { ' . $opts{ban} . " }'";

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
and lowercased, then removed from the family-appropriate set via
C<nft delete element>. Unbanning an IP that is not banned is a noop.

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

	my ( $table, $set4, $set6 ) = $self->_names;
	my $set = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;

	my $command = "nft 'delete element inet " . $table . ' ' . $set . ' { ' . $opts{ban} . " }'";

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
retained in-memory state; the sets are not queried.

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

Tears down and re-initiates the backend, recreating the table, chain, sets,
and rules, then re-adds every previously banned IP to the relevant set via
C<nft add element>. The teardown is best effort as a partially or fully
wiped setup is exactly what this needs to recover from.

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

	my ( $table, $set4, $set6 ) = $self->_names;

	my @to_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $set = ( $item =~ /\A$IPv4_re\z/ ) ? $set4 : $set6;
		my $command = "nft 'add element inet " . $table . ' ' . $set . ' { ' . $item . " }'";

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

Tears down the setup for the backend by deleting the table, which removes
the chain, sets, and rules with it.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my ( $table, $set4, $set6 ) = $self->_names;

	my @commands = ( "nft 'delete table inet " . $table . "'" );

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

Verifies that the table is still present and that the chain still contains
rules referencing each set the block rules use. Returns a true value if the
setup is intact and a false value if any part of it appears to have been
removed. This is the equivalent of fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my ( $table, $set4, $set6 ) = $self->_names;

	my ( $specs, $referenced ) = $self->_rule_specs;

	my @commands = ( "nft 'list table inet " . $table . "'" );
	foreach my $set ( sort( keys( %{$referenced} ) ) ) {
		push( @commands, "nft 'list chain inet " . $table . ' ' . $table . "' | grep -q '\@" . $set . "'" );
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

Removes all currently banned IPs at once by flushing both sets, leaving the
table, chain, and rules in place. This is the equivalent of fail2ban's
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

	my ( $table, $set4, $set6 ) = $self->_names;

	my @commands = (
		"nft 'flush set inet " . $table . ' ' . $set4 . "'",
		"nft 'flush set inet " . $table . ' ' . $set6 . "'",
	);

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

=head2 19, priorityInvalid

The option priority is not an int.

=head2 20, typeInvalid

The option type is not "drop" or "reject".

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
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
