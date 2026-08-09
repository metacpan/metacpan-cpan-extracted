package Net::Firewall::BlockerHelper::backends::ipfw;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::ipfw - IPFW backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

The block rules this backend creates are added straight into the main
ruleset at the configured rule number, the C<rule> option, default 150, so
no additional wiring is needed for them to be evaluated. What does need
minding is placement, as ipfw is first match wins. The rule number needs to
be lower than that of any rule that would pass the traffic in question,
such as a C<check-state> or an allow rule, otherwise the bans will never
match anything.

    use Net::Firewall::BlockerHelper::backends::ipfw;

    my $backend1;
    my $backend2;
    eval {
        $backend1 = Net::Firewall::BlockerHelper::backends::ipfw->new(
                backend => 'ipfw',
                name => 'all',
                options=>{ rule=>150, kill=>1 },
            );
        $backend2 = Net::Firewall::BlockerHelper::backends::ipfw->new(
                backend => 'ipfw',
                ports => ['143'],
                protocols => ['tcp'],
                name => 'imap',
                options=>{ rule=>151 },
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

    print `ipfw list`

    $backend1->init;
    $backend2->init;

    print `ipfw list`

    $backend1->ban(ban=>'1.2.3.4');
    $backend1->ban(ban=>'4.3.2.1');
    $backend2->ban(ban=>'4.3.2.1');

    use Data::Dumper;
    print Dumper($backend1->list);
    print Dumper($backend2->list);

    $backend1->unban(ban=>'4.3.2.1');

    use Data::Dumper;
    print Dumper($backend1->list);
    print Dumper($backend2->list);

    $backend1->teardown;

    print `ipfw list`

    $backend2->teardown;

    print `ipfw list`

=head1 METHODS

=head2 new

Initiates the object. Takes the arguments below.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for furhter info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are positive ints or a valid
            service name via getservbyname. All ports will be blocked if non are specified. If
            duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. This is checked against
            /etc/protocols via the function getprotobyname. Duplicates will be
            discarded. If no protocols are given, all IPv4 and IPv6 traffic is
            blocked ('ip4' and 'ip6'), unless ports are given, in which case it
            defaults to tcp and udp. Ports are only attached to port-capable
            protocols (tcp/udp/sctp); other protocols are blocked without a
            port. As the ipfw 'me' keyword only matches IPv4 addresses and
            'me6' only IPv6 ones, family neutral protocols such as tcp/udp
            get one rule per family while family specific ones such as icmp or
            ip6 get a single rule for their family.
        - Default :: ['ip4','ip6'], or ['tcp','udp'] when ports are given

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - rule :: The rule number to use for the IPFW rules. This should not
            be re-used or it will result in the other rules at that number
            being removed when init is called.
        - Default :: 150

    - type :: The drop method to use. 'deny' silently drops. 'unreach' and
            'unreach6' both mean reject, and are treated as synonyms: the
            family of each generated rule decides whether an IPv4 unreach or
            an IPv6 unreach6 is sent, using the unreach and unreach6 codes
            below. See ipfw(8) for more info.
        - Default :: deny

    - unreach :: The IPv4 unreach code to use when type is a reject. Applied
            to IPv4 protocols. See ipfw(8) for more info.
        - Default :: port

    - unreach6 :: The IPv6 unreach6 code to use when type is a reject. Applied
            to IPv6 protocols. See ipfw(8) for more info.
        - Default :: port

    - kill :: Use tcpdrop to kill TCP connections for that IP. Handles both
            IPv4 and IPv6, picking the sockstat family and parsing per the
            family of the banned IP. TCP only, as FreeBSD has no tcpdrop
            equivalent for UDP; since the generated rules are stateless, UDP
            from the banned IP is blocked immediately regardless, so there is
            no lingering flow state to clear. If protocols are configured and
            tcp is not among them, nothing is killed, so blocking only udp
            never drops TCP connections.
        - Default :: 0

All errors are considered fatal, meaning if new fails it will die.

    my $backend;
    eval {
        $backend = Net::Firewall::BlockerHelper::backends::ipfw->new(
                backend => 'ipfw',
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
				19 => 'ruleInvalid',
				20 => 'typeInvalid',
				21 => 'unreachInvalid',
				22 => 'unreach6Invalid',
				23 => 'initFailed',
				26 => 'nameTooLong',
				24 => 'checkFailed',
				25 => 'flushFailed',
				27 => 'banCidrFailed',
				28 => 'unbanCidrFailed',
				29 => 'cidrItemNotCidr',
				30 => 'cidrNotSupported',
				31 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options => {
			rule     => 150,
			type     => 'deny',
			unreach  => 'port',
			unreach6 => 'port',
			kill     => 0,
		},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		frontend_obj => undef,
		inited         => 0,
		banned         => {},
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

	# ipfw limits table names to 63 characters and the table is
	# <prefix>_<name>, so catch over-long combos here rather than as a
	# confusing error at init
	if ( defined( $self->{name} ) && length( $self->{prefix} . '_' . $self->{name} ) > 63 ) {
		$self->{perror} = 1;
		$self->{error}  = 26;
		$self->{errorString}
			= 'the combined prefix and name, "'
			. $self->{prefix} . '_'
			. $self->{name}
			. '", is longer than 63 characters, the max ipfw table name length';
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

		if ( defined( $opts{options}{rule} ) && ref( $opts{options}{rule} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 19;
			$self->{errorString} = 'ref for $opts{options}{rule} is "' . ref( $opts{options}{rule} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{rule} ) && $opts{options}{rule} !~ /^[0-9]+$/ ) {
			$self->{perror}      = 1;
			$self->{error}       = 19;
			$self->{errorString} = '$opts{options}{rule} is "' . $opts{options}{rule} . '" and not "150"';
			$self->warn;
		} elsif ( defined( $opts{options}{rule} ) && $opts{options}{rule} < 1 ) {
			$self->{perror}      = 1;
			$self->{error}       = 19;
			$self->{errorString} = '$opts{options}{rule} is "' . $opts{options}{rule} . '" is less than 1';
			$self->warn;
		} elsif ( !defined( $opts{options}{rule} ) ) {
			$self->{options}{rule} = 150;
		}

		if ( defined( $opts{options}{type} ) && ref( $opts{options}{type} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 20;
			$self->{errorString} = 'ref for $opts{options}{type} is "' . ref( $opts{options}{type} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{type} )
			&& $opts{options}{type} ne 'unreach'
			&& $opts{options}{type} ne 'deny'
			&& $opts{options}{type} ne 'unreach6' )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "' . $opts{options}{type} . '" and not "deny", "unreach", or "unreach6"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'deny';
		}

		if ( defined( $opts{options}{unreach} ) && ref( $opts{options}{unreach} ) ne '' ) {
			$self->{perror} = 1;
			$self->{error}  = 21;
			$self->{errorString}
				= 'ref for $opts{options}{unreach} is "' . ref( $opts{options}{unreach} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{unreach} )
			&& $opts{options}{unreach} ne 'net'
			&& $opts{options}{unreach} ne 'host'
			&& $opts{options}{unreach} ne 'protocol'
			&& $opts{options}{unreach} ne 'port'
			&& $opts{options}{unreach} ne 'needfrag'
			&& $opts{options}{unreach} ne 'srcfail'
			&& $opts{options}{unreach} ne 'net-unknown'
			&& $opts{options}{unreach} ne 'host-unknown'
			&& $opts{options}{unreach} ne 'isolated'
			&& $opts{options}{unreach} ne 'net-prohib'
			&& $opts{options}{unreach} ne 'host-prohib'
			&& $opts{options}{unreach} ne 'tosnet'
			&& $opts{options}{unreach} ne 'toshost'
			&& $opts{options}{unreach} ne 'filter-prohib'
			&& $opts{options}{unreach} ne 'host-precedence'
			&& $opts{options}{unreach} ne 'precedence-cutoff' )
		{
			$self->{perror} = 1;
			$self->{error}  = 21;
			$self->{errorString}
				= '$opts{options}{unreach} is "'
				. $opts{options}{unreach}
				. '" and a value understood by ipfw(8) for unreach';
			$self->warn;
		} elsif ( !defined( $opts{options}{unreach} ) ) {
			$self->{options}{unreach} = 'port';
		}

		if ( defined( $opts{options}{unreach6} ) && ref( $opts{options}{unreach6} ) ne '' ) {
			$self->{perror} = 1;
			$self->{error}  = 22;
			$self->{errorString}
				= 'ref for $opts{options}{unreach6} is "' . ref( $opts{options}{unreach6} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{options}{unreach6} )
			&& $opts{options}{unreach6} ne 'no-route'
			&& $opts{options}{unreach6} ne 'admin-prohib'
			&& $opts{options}{unreach6} ne 'address'
			&& $opts{options}{unreach6} ne 'port' )
		{
			$self->{perror} = 1;
			$self->{error}  = 22;
			$self->{errorString}
				= '$opts{options}{unreach6} is "'
				. $opts{options}{unreach6}
				. '" and a value understood by ipfw(8) for unreach6';
			$self->warn;
		} elsif ( !defined( $opts{options}{unreach6} ) ) {
			$self->{options}{unreach6} = 'port';
		}

	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

=head2 init

Initiates the backend. First any old remnants are removed on a best effort
basis, deleting the configured rule number and then destroying the table
C<E<lt>prefixE<gt>_E<lt>nameE<gt>>, with failures ignored. The rule goes
first as ipfw will not destroy a table a rule still references. The table is then created
via C<ipfw table ... create> and a block rule is added at the configured rule
number for each configured protocol, matching from C<table(...)> to C<me> or
C<me6> depending on the family, with the configured ports appended for
port-capable protocols (tcp/udp/sctp). The action is C<deny> or, for reject
types, C<unreach>/C<unreach6> per the family of the rule.

Note that as ipfw is first match wins, the configured rule number needs to
come before any rules that would pass the traffic. See L</SYNOPSIS>.

No arguments are taken.

If called a second time, it will error.

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

	my $ports;
	if ( defined( $self->{ports}[0] ) ) {
		$ports = join( ',', @{ $self->{ports} } );
	}

	my @protocols;
	if ( defined( $self->{protocols}[0] ) ) {
		push( @protocols, @{ $self->{protocols} } );
	} elsif ( defined($ports) ) {
		# ports need a port-capable protocol, default to tcp and udp
		push( @protocols, 'tcp', 'udp' );
	} else {
		# block all, both IPv4 and IPv6; ip4/ip6 are used rather than ip as
		# in ipfw 'ip' means any packet, not IPv4, per ipfw(8)
		push( @protocols, 'ip4', 'ip6' );
	}

	# protocols that accept a port specification
	my %port_ok = ( tcp => 1, udp => 1, sctp => 1 );

	# in ipfw 'me' matches only IPv4 addresses on the system and 'me6' only
	# IPv6 ones, so each rule must be emitted for the right family; family
	# neutral protocols such as tcp/udp get one rule per family
	my %is_v6 = ( ip6 => 1, ipv6 => 1, icmp6 => 1, 'ipv6-icmp' => 1, icmpv6 => 1 );
	my %is_v4 = ( ip4 => 1, ipv4 => 1, icmp => 1, igmp => 1 );

	# the rule has to go before the table it references, as ipfw refuses to
	# destroy a table that is still in use by a rule; destroying first leaves
	# the table behind and the create below then fails with "File exists"
	my @fail_okay_commands;
	push( @fail_okay_commands, 'ipfw delete ' . $self->{options}{rule} );
	push( @fail_okay_commands, 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' destroy' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{fail_okay_commands} = \@fail_okay_commands;
	} else {
		foreach my $item (@fail_okay_commands) {
			my $output = `$item  2>&1`;
		}
	}

	my @commands;
	# add the table to create the command
	push( @commands, 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' create' );

	# generates the block rules
	foreach my $item (@protocols) {
		# family specific protocols get one rule for their family; family
		# neutral protocols such as tcp/udp get a rule for each family
		my @families;
		if ( $is_v6{$item} ) {
			@families = (6);
		} elsif ( $is_v4{$item} ) {
			@families = (4);
		} else {
			@families = ( 4, 6 );
		}

		foreach my $family (@families) {
			# type is deny vs reject; for a reject the family of the rule
			# decides between unreach (IPv4) and unreach6 (IPv6)
			my $action;
			if ( $self->{options}{type} eq 'deny' ) {
				$action = 'deny';
			} elsif ( $family == 6 ) {
				$action = 'unreach6 ' . $self->{options}{unreach6};
			} else {
				$action = 'unreach ' . $self->{options}{unreach};
			}

			my $command
				= 'ipfw add '
				. $self->{options}{rule} . ' '
				. $action . ' '
				. $item
				. ' from "table('
				. $self->{prefix} . '_'
				. $self->{name}
				. ')" to '
				. ( $family == 6 ? 'me6' : 'me' );
			if ( defined($ports) && $port_ok{$item} ) {
				$command = $command . ' ' . $ports;
			}
			push( @commands, $command );
		} ## end foreach my $family (@families)
	} ## end foreach my $item (@protocols)

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
and lowercased, then added to the IPFW table via
C<ipfw table E<lt>prefixE<gt>_E<lt>nameE<gt> add>. If the kill option is set
and tcp is among the blocked protocols, established TCP connections from the
IP are found via sockstat and killed via tcpdrop. Banning an already banned
IP is a noop.

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

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' add ' . $opts{ban};

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

	# tcpdrop only handles TCP, so only kill when tcp is among the blocked
	# protocols; no protocols configured means everything is being blocked,
	# tcp included
	my $kill_applicable = !defined( $self->{protocols}[0] ) || ( grep { $_ eq 'tcp' } @{ $self->{protocols} } );

	if ( $self->{options}{kill} && $kill_applicable ) {
		if ( $opts{ban} =~ /\A$IPv4_re\z/ ) {
			# for IPv4 every colon is a address/port separator, so a simple
			# split works; -wF so the IP is matched as a fixed string and not
			# as a regexp, preventing 1.2.3.4 from also matching 11.2.3.45
			$command
				= 'sockstat -nc4 -P tcp |sed "s/.*tcp[46]  *//" | sed "s/:/ /g" | grep -wF '
				. $opts{ban}
				. ' | xargs -n 4 tcpdrop';
		} else {
			# for IPv6 the address itself contains colons, so only the last
			# colon of each field, the port, is turned into a space, and any
			# scope ID is stripped as tcpdrop does not take them
			$command
				= 'sockstat -nc6 -P tcp |sed "s/.*tcp[46]  *//" | grep -E "(^|[[:space:]])'
				. $opts{ban}
				. ':[0-9]+([[:space:]]|\$)" | sed "s/%[a-zA-Z0-9]*//g" | sed -E "s/:([0-9]+)([[:space:]]|\$)/ \\1\\2/g" | xargs -n 4 tcpdrop';
		}
		if ( $self->{testing} ) {
			push( @{ $self->{frontend_obj}->{test_data} }, $command );
		} else {
			my $output = `$command 2>&1`;
		}
	} ## end if ( $self->{options}{kill} )

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the IPFW table via
C<ipfw table E<lt>prefixE<gt>_E<lt>nameE<gt> delete>. Unbanning an IP that
is not banned is a noop.

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

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' delete ' . $opts{ban};

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

=head2 ban_cidr

Bans a CIDR range by adding it to the IPFW table. IPFW tables accept a
network prefix in the same manner as a single address.

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
		$self->{error}       = 29;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 29;
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

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' add ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 27;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by deleting it from the IPFW table.

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
		$self->{error}       = 29;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 29;
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

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' delete ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 28;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges.

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

Tells the backend to re-init itself.

Calls teardown, with errors ignored as a partially wiped setup is what
re_init recovers from, then init to recreate the table and rules. All
previously banned IPs and CIDR ranges are then re-added to the table via
C<ipfw table ... add>.

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

	my @to_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' add ' . $item;

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

Tears down the setup for the backend, deleting the configured rule number and
then destroying the table C<E<lt>prefixE<gt>_E<lt>nameE<gt>>.

The ordering matters. ipfw will not destroy a table that is still in use by a
rule, so the rule is removed first; doing it the other way round leaves the
table behind.

Both commands are always attempted, and a failure of either is raised only
once both have run, so a rule that has already been removed does not stop the
table from being destroyed.

It does not check if it has been inited or not, so if called prior to
calling init, it will error as the commands will fail.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# the rule has to go before the table it references, as ipfw refuses to
	# destroy a table that is still in use by a rule
	my @commands;
	push( @commands, 'ipfw delete ' . $self->{options}{rule} );
	push( @commands, 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' destroy' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		# every command is attempted before anything is raised. errors are
		# fatal, so warning inside the loop would abort it and leave the rest
		# of the setup in place; a rule that is already gone must not stop the
		# table from being destroyed
		my @failures;
		foreach my $item (@commands) {
			my $output = `$item  2>&1`;
			if ( $? != 0 ) {
				push( @failures, 'command... "' . $item . '"... output... ' . $output );
			}
		}

		if (@failures) {
			$self->{error}       = 17;
			$self->{errorString} = 'teardown failed. non-zero exit code for the ' . join( ' and the ', @failures );
			$self->warn;
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

Verifies that the IPFW table is still present and that the rule number still
exists. Returns a true value if the setup is intact and a false value if any
part of it appears to have been removed. This is the equivalent of fail2ban's
C<actioncheck>.

    if ( !$backend->check ) {
        $backend->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my @commands = (
		'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' info',
		'ipfw list ' . $self->{options}{rule},
	);

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

Removes all currently banned IPs and CIDR ranges at once by flushing the
IPFW table, leaving the table and rule in place. This is the equivalent of
fail2ban's C<actionflush>.

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

	my @commands = ( 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' flush' );

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

	# the table flush above removes both single IP and CIDR entries at once
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

=head2 5, invalidPortSpecified

Port is either not an int within the range 1 to 65535 or a name that can be resolved by getservbyname.

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

=head2 19, ruleInvalid

The option rule is not an int of 1 or greater.

=head2 20, typeInvalid

The option type is not "deny", "unreach", or "unreach6".

=head2 21, unreachInvalid

The option unreach is not a value understood by ipfw(8) for unreach.

=head2 22, unreach6Invalid

The option unreach6 is not a value understood by ipfw(8) for unreach6.

=head2 23, initFailed

One of the required commands for init failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, nameTooLong

The combined prefix and name is longer than 63 characters, the max ipfw
table name length.

=head2 27, banCidrFailed

Failed to ban the CIDR range.

=head2 28, unbanCidrFailed

Failed to unban the CIDR range.

=head2 29, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 30, cidrNotSupported

The backend does not support CIDR bans.

=head2 31, listCidrFailed

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
