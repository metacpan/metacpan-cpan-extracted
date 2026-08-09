package Net::Firewall::BlockerHelper::backends::firewalld;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::firewalld - firewalld backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'firewalld',
            ports => ['22'],
            protocols => ['tcp'],
            name => 'ssh',
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');
    $fw_helper->teardown;

=head1 DESCRIPTION

Blocks IPs on hosts managed by L<firewalld(1)>, where using the iptables
backend directly would fight the daemon and be lost on reload.

Like the iptables backend, two ipsets are created via L<ipset(8)>, one for
IPv4 (C<< <prefix>_<name>_4 >>) and one for IPv6 (C<< <prefix>_<name>_6 >>).
The block rules are inserted through the firewalld direct interface
(C<firewall-cmd --direct>) into the configured chain (INPUT_direct by
default). Banning an IP adds it to the relevant ipset.

Requires C<firewall-cmd> and C<ipset> to be installed and in the C<PATH> of
the process, which must have sufficient privileges to run them. firewalld
must be running.

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
            /etc/protocols via the function getprotobyname. Duplicates will be
            discarded. If no protocols are given, everything sourced from the
            sets is blocked, unless ports are given, in which case it defaults
            to tcp and udp. Ports are only attached to port-capable protocols
            (tcp/udp/sctp); other protocols are blocked without a port.
        - Default :: [], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - type :: The drop method to use. Should either be 'drop' or 'reject'.
            'reject' sends an ICMP port-unreachable back.
        - Default :: drop

    - chain :: The direct interface chain to add the rules to.
            Must match /^[a-zA-Z0-9_\-]+$/. Only the *_direct chains,
            such as the default, are called automatically by firewalld;
            a custom chain must already exist and be jumped to from
            somewhere in the ruleset or the rules will never be evaluated.
        - Default :: INPUT_direct

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
				19 => 'chainInvalid',
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
			type  => 'drop',
			chain => 'INPUT_direct',
			kill  => 0,
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

	# ipset limits set names to 31 characters and the sets are
	# <prefix>_<name>_4/_6, so catch over-long combos here rather than as a
	# confusing error at init
	if ( defined( $self->{name} ) && length( $self->{prefix} . '_' . $self->{name} ) > 29 ) {
		$self->{perror} = 1;
		$self->{error}  = 21;
		$self->{errorString}
			= 'the combined prefix and name, "'
			. $self->{prefix} . '_'
			. $self->{name}
			. '", is longer than 29 characters, leaving no room for the _4/_6 suffix within the 31 character ipset name limit';
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

		if ( defined( $opts{options}{chain} ) && $opts{options}{chain} !~ /^[a-zA-Z0-9_\-]+$/ ) {
			$self->{perror} = 1;
			$self->{error}  = 19;
			$self->{errorString}
				= '$opts{options}{chain} is "'
				. $opts{options}{chain}
				. '" and does not match /^[a-zA-Z0-9_\-]+$/';
			$self->warn;
		} elsif ( !defined( $opts{options}{chain} ) ) {
			$self->{options}{chain} = 'INPUT_direct';
		}
	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

# Internal helper. Returns the names of the two ipsets this instance owns.
#
# Both are derived from the prefix and the name rather than stored, so every
# part of the backend agrees on what to create, match against, and tear down
# without threading the names around. The prefix and name pair is unique per
# instance, so two instances can share a host without colliding.
#
# There are two sets because an ipset is single family: a hash:ip set is
# created either family inet or family inet6 and will not hold addresses of
# the other. Note firewalld manages the sets itself, via firewall-cmd
# --new-ipset, rather than the ipset command being called directly.
#
# Unlike the iptables backend there is no chain name here. This backend adds
# its rules through firewalld's direct interface rather than owning a chain of
# its own, so there is nothing else to name.
#
# Takes no arguments.
#
# Returns a two element list of the IPv4 set name and the IPv6 set name, in
# that order.
#
#     my ( $set4, $set6 ) = $self->_set_names;
#
#     # with prefix "kur" and name "ssh"
#     #   $set4 is 'kur_ssh_4'
#     #   $set6 is 'kur_ssh_6'
sub _set_names {
	my ($self) = @_;

	my $base = $self->{prefix} . '_' . $self->{name};
	return ( $base . '_4', $base . '_6' );
}

# Internal helper. Works out the full cross product of family, protocol, and
# ports this instance needs to block, and returns it as the argument strings
# for firewalld's direct interface. Essentially all of the backend's rule
# logic lives here.
#
# The rules go in through firewall-cmd --direct --add-rule, which takes a
# family and then passes the rest through to iptables more or less verbatim.
# That is why the argument strings are iptables syntax rather than anything
# firewalld specific, and why the family has to be handed over separately as
# 'ipv4' or 'ipv6' instead of being implied by which binary is invoked.
#
# The target is chosen per family because reject needs a different ICMP type
# for each. Protocols belonging to the wrong family are skipped, so icmp never
# lands in an ipv6 rule and the various spellings of IPv6 ICMP never land in
# an ipv4 one. Ports are only attached to protocols that actually have them.
#
# Unlike the iptables backend there is no tarpit or delude here, so there is
# no TCP only restriction and no conntrack exemption to generate.
#
# Takes no arguments; family, protocols, ports, and type all come from the
# object.
#
# Returns a list of hashrefs, one per rule to be created, each of the form:
#
#     {
#         fam  => 'ipv4',    # or 'ipv6', for the --direct family argument
#         args => '-m set --match-set kur_ssh_4 src -j DROP',
#     }
#
# The args are the complete rule body after the chain, ready to be appended to
# a --direct --add-rule invocation. The list is empty only if every protocol
# was filtered out.
#
#     # no protocols and no ports, type drop
#     my @rules = $self->_rule_args;
#     #   { fam => 'ipv4', args => '-m set --match-set kur_ssh_4 src -j DROP' }
#     #   { fam => 'ipv6', args => '-m set --match-set kur_ssh_6 src -j DROP' }
#
#     # type reject, protocols tcp, ports 22
#     #   { fam => 'ipv4', args => '-m set --match-set kur_ssh_4 src -p tcp -m multiport --dports 22 -j REJECT --reject-with icmp-port-unreachable' }
#     #   { fam => 'ipv6', args => '-m set --match-set kur_ssh_6 src -p tcp -m multiport --dports 22 -j REJECT --reject-with icmp6-port-unreachable' }
sub _rule_args {
	my ($self) = @_;

	my ( $set4, $set6 ) = $self->_set_names;

	my @ports    = @{ $self->{ports} };
	my @protos   = @{ $self->{protocols} };
	my $port_str = join( ',', @ports );

	# work out the target for each family
	my $t4 = 'DROP';
	my $t6 = 'DROP';
	if ( $self->{options}{type} eq 'reject' ) {
		$t4 = 'REJECT --reject-with icmp-port-unreachable';
		$t6 = 'REJECT --reject-with icmp6-port-unreachable';
	}

	# protocols that accept a port specification
	my %port_ok = ( tcp => 1, udp => 1, sctp => 1 );

	# the various names the IPv6 ICMP protocol may go by
	my %v6_icmp = ( 'ipv6-icmp' => 1, 'icmp6' => 1, 'icmpv6' => 1 );

	my @families = (
		{ fam => 'ipv4', set => $set4, tgt => $t4, family => 4 },
		{ fam => 'ipv6', set => $set6, tgt => $t6, family => 6 },
	);

	my @rules;
	foreach my $fam (@families) {
		my $base = '-m set --match-set ' . $fam->{set} . ' src';

		if ( !@protos && !@ports ) {
			# block everything sourced from the set
			push( @rules, { fam => $fam->{fam}, args => $base . ' -j ' . $fam->{tgt} } );
		} elsif ( !@protos && @ports ) {
			# ports require a protocol, default to tcp and udp
			foreach my $proto ( 'tcp', 'udp' ) {
				push(
					@rules,
					{
						fam  => $fam->{fam},
						args => $base . ' -p ' . $proto . ' -m multiport --dports ' . $port_str . ' -j ' . $fam->{tgt}
					}
				);
			}
		} else {
			foreach my $proto (@protos) {
				# skip protocols that do not belong to this family
				if ( $fam->{family} == 6 ) {
					next if ( $proto eq 'icmp' );
				} else {
					next if ( $v6_icmp{$proto} );
				}

				my $args = $base . ' -p ' . $proto;
				if ( @ports && $port_ok{$proto} ) {
					$args .= ' -m multiport --dports ' . $port_str;
				}
				$args .= ' -j ' . $fam->{tgt};
				push( @rules, { fam => $fam->{fam}, args => $args } );
			} ## end foreach my $proto (@protos)
		} ## end else [ if ( !@protos && !@ports ) ]
	} ## end foreach my $fam (@families)

	return @rules;
} ## end sub _rule_args

=head2 init

Initiates the backend. Any stale direct rules and ipsets from a previous
run are removed first, with failures ignored. Then the two ipsets are
created via C<ipset create> and the block rules are added to the configured
chain via C<firewall-cmd --direct --add-rule>.

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

	my ( $set4, $set6 ) = $self->_set_names;
	my $chain = $self->{options}{chain};

	my @rules = $self->_rule_args;

	# stale state cleanup, allowed to fail
	my @fail_okay_commands;
	foreach my $rule (@rules) {
		push( @fail_okay_commands,
			'firewall-cmd --direct --remove-rule ' . $rule->{fam} . ' filter ' . $chain . ' 0 ' . $rule->{args} );
	}
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
	push( @commands, 'ipset create ' . $set4 . ' hash:ip family inet' );
	push( @commands, 'ipset create ' . $set6 . ' hash:ip family inet6' );
	foreach my $rule (@rules) {
		push( @commands,
			'firewall-cmd --direct --add-rule ' . $rule->{fam} . ' filter ' . $chain . ' 0 ' . $rule->{args} );
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
and lowercased, then added to the relevant ipset via C<ipset add>. If the
kill option is set, conntrack(8) is used to drop existing connection
tracking entries for the IP. Banning an already banned IP is a noop.

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
and lowercased, then removed from the relevant ipset via C<ipset del>.
Unbanning an IP that is not banned is a noop.

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

List banned IPs. Returns an array of the currently banned IPs.

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

This will call teardown and init again. After that it will re-add all
previously added bans via C<ipset add>.

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

This will remove the direct rules and the ipsets.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my ( $set4, $set6 ) = $self->_set_names;
	my $chain = $self->{options}{chain};

	my @commands;
	foreach my $rule ( $self->_rule_args ) {
		push( @commands,
			'firewall-cmd --direct --remove-rule ' . $rule->{fam} . ' filter ' . $chain . ' 0 ' . $rule->{args} );
	}
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

Verifies that firewalld is running, the ipsets are still present, and each
of the direct rules is still in place. Returns a true value if the setup is
intact and a false value if any part is missing. This is the equivalent of
fail2ban's C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my ( $set4, $set6 ) = $self->_set_names;
	my $chain = $self->{options}{chain};

	my @commands = ( 'firewall-cmd --state', 'ipset list ' . $set4, 'ipset list ' . $set6 );
	foreach my $rule ( $self->_rule_args ) {
		push( @commands,
			'firewall-cmd --direct --query-rule ' . $rule->{fam} . ' filter ' . $chain . ' 0 ' . $rule->{args} );
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
rules in place. This is the equivalent of fail2ban's C<actionflush>.

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

=head2 19, chainInvalid

The option chain does not match /^[a-zA-Z0-9_\-]+$/.

=head2 20, typeInvalid

The option type is either a ref or not "drop" or "reject".

=head2 21, nameTooLong

The combined prefix and name is longer than 29 characters, leaving no room
for the _4/_6 suffix within the 31 character ipset name limit.

=head2 23, initFailed

Init failed. A command run during init exited non-zero.

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
