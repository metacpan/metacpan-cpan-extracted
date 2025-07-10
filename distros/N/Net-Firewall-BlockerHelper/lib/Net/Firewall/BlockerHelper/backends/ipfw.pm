package Net::Firewall::BlockerHelper::backends::ipfw;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::ipfw - IPFW backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

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

Initiates the the object.

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined. See below for furhter info.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are positive ints or a valid
            service name via getservbyname. All ports will be blocked if non are specified. If
            duplicates are removed.
        - Default :: []

    - protocols :: A array of protocols to block. By default will block all. This
            is checked against /etc/protocols via the function getprotobyname. Duplicates
            will be discarded.
        - Default :: ['ip']

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

The options hash accepts the following.

    - rule :: The rule name to use for the IPFW rule. This should not
            re-used or it will result in the other rules being removed
            when init is called.
        - Default :: 150

    - type :: The drop method to use. Should either be 'deny',
            'unreach', or 'unreach6'. See ipfw(8) for more info.
        - Default :: deny

    - unreach :: The if using unreach, the unreach type to use.
            See ipfw(8) for more info.
        - Default :: port

    - unreach6 :: The if using unreach, the unreach type to use.
            See ipfw(8) for more info.
        - Default :: port

    - kill :: Use tcpdrop to kill TCP connections for that IP.
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
		postfix      => undef,
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
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
			if ( $item =~ /^[0-9]+$/ && $item >= 1 ) {
				$ports{$item} = 1;
			} elsif ( $item =~ /^[0-9]+$/ && $item < 1 ) {
				$self->{perror} = 1;
				$self->{error}  = 2;
				$self->{errorString}
					= $item . ' is not a valid value for a port as it must be a int greater or equal to 1';
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
					= $item . ' could not be resolved to a port name via getservbyname("' . $item . '", "tcp")';
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
		$self->{error}       = 6;
		$self->{errorString} = 'name is undef';
		$self->warn;
	} elsif ( $opts{name} !~ /^[a-zA-Z0-9\-]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 6;
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

		if ( defined( $opts{optsions}{type} ) && ref( $opts{options}{type} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 20;
			$self->{errorString} = 'ref for $opts{options}{type} is "' . ref( $opts{options}{type} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{optsions}{type} )
			&& $opts{optsions}{type} ne 'unreach'
			&& $opts{optsions}{type} ne 'deny'
			&& $opts{optsions}{type} ne 'unreach6' )
		{
			$self->{perror} = 1;
			$self->{error}  = 20;
			$self->{errorString}
				= '$opts{options}{type} is "' . $opts{options}{type} . '" and not "deny", "unreach", or "unreach6"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'deny';
		}

		if ( defined( $opts{optsions}{unreach} ) && ref( $opts{options}{unreach} ) ne '' ) {
			$self->{perror} = 1;
			$self->{error}  = 21;
			$self->{errorString}
				= 'ref for $opts{options}{unreach} is "' . ref( $opts{options}{unreach} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{optsions}{unreach} )
			&& $opts{optsions}{unreach} ne 'net'
			&& $opts{optsions}{unreach} ne 'host'
			&& $opts{optsions}{unreach} ne 'protocol'
			&& $opts{optsions}{unreach} ne 'port'
			&& $opts{optsions}{unreach} ne 'needfrag'
			&& $opts{optsions}{unreach} ne 'srcfail'
			&& $opts{optsions}{unreach} ne 'net-unknown'
			&& $opts{optsions}{unreach} ne 'host-unknown'
			&& $opts{optsions}{unreach} ne 'isolated'
			&& $opts{optsions}{unreach} ne 'net-prohib'
			&& $opts{optsions}{unreach} ne 'host-prohib'
			&& $opts{optsions}{unreach} ne 'tosnet'
			&& $opts{optsions}{unreach} ne 'toshost'
			&& $opts{optsions}{unreach} ne 'filter-prohib'
			&& $opts{optsions}{unreach} ne 'host-precedence'
			&& $opts{optsions}{unreach} ne 'precedence-cutoff' )
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

		if ( defined( $opts{optsions}{unreach6} ) && ref( $opts{options}{unreach6} ) ne '' ) {
			$self->{perror} = 1;
			$self->{error}  = 22;
			$self->{errorString}
				= 'ref for $opts{options}{unreach6} is "' . ref( $opts{options}{unreach6} ) . '" and not ""';
			$self->warn;
		} elsif ( defined( $opts{optsions}{unreach6} )
			&& $opts{optsions}{unreach6} ne 'no-route'
			&& $opts{optsions}{unreach6} ne 'admin-prohib'
			&& $opts{optsions}{unreach6} ne 'address'
			&& $opts{optsions}{unreach6} ne 'port' )
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

Initiates the backend. This will attempt to drop the rule number and table
prior to re-adding them.

No arguments are taken.

May called a second time, it will error.

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
	} else {
		push( @protocols, 'ip' );
	}

	my @fail_okay_commands;
	push( @fail_okay_commands, 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' destroy' );
	push( @fail_okay_commands, 'ipfw delete ' . $self->{options}{rule} );

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
		my $command = 'ipfw add ' . $self->{options}{rule} . ' ' . $self->{options}{type} . ' ';
		if ( $self->{options}{type} ne 'deny' ) {
			$command = $command . $self->{options}{ $self->{options}{type} } . ' ';
		}
		$command = $command . $item . ' from "table(' . $self->{prefix} . '_' . $self->{name} . ')" to me';
		if ( defined($ports) ) {
			$command = $command . ' ' . $ports;
		}
		push( @commands, $command );
	} ## end foreach my $item (@protocols)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data}{commands} = \@commands;
	} else {
		foreach my $item (@fail_okay_commands) {
			my $output = `$item 2>&1`;
			if ( $? ne '0' ) {
				$self->{error} = 22;
				$self->{errorString}
					= 'init failed. non-zero exit code for the dommand... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans the IP.

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
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	if ( $self->{banned}{ $opts{ban} } ) {
		$self->{frontend_obj}->{test_data} = 'already banned';
		return;
	}

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' add ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		my $output = `$command 2>&1`;
		if ( $? ne '0' ) {
			$self->{error} = 13;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	if ( $self->{options}{kill} ) {
		$command
			= 'sockstat -nc4 -P tcp |sed "s/.*tcp[46]  *//" | sed "s/:/ /g" | grep -i '
			. $opts{ban}
			. ' | xargs -n 4 tcpdrop';
		if ( $self->{testing} ) {
			push( @{ $self->{frontend_obj}->{test_data} }, $command );
		} else {
			my $output = `$command 2>&1`;
		}

		$command
			= 'sockstat -n6 -P udp | grep -i '
			. $opts{ban}
			. ' | perl -lpe \'$_=~s/.*udp[46]  *//; $_=~s/:([0-9]+) / $1 /; $_=~s/:([0-9]+)$/ $1/; $_=~s/\%[a-zA-Z0-9]+/ /g ; print $_\'';
		if ( $self->{testing} ) {
			push( @{ $self->{frontend_obj}->{test_data} }, $command );
		} else {
			my $output = `$command 2>&1`;
		}
	} ## end if ( $self->{options}{kill} )

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans the an IP.

    $backend->ban(ban => $ip);

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
	} elsif ( $opts{ban} !~ /$IPv4_re/
		&& $opts{ban} !~ /$IPv6_re/ )
	{
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 or IPv6 IP';
		$self->warn;
		return;
	}

	if ( !$self->{banned}{ $opts{ban} } ) {
		$self->{frontend_obj}->{test_data} = 'not banned';
		return;
	}

	my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' delete ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? ne '0' ) {
			$self->{error} = 14;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 list

List banned IPs.

    my @banned = $backend->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{frontend_obj}->{test_data} = 'list';

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

	if ( !$self->{inited} ) {
		$self->{error}       = 1;
		$self->{errorString} = 'backend has not been inited';
		$self->warn;
		return;
	}

	$self->teardown;
	$self->init;

	my @to_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $command = 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' add ' . $item;

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? ne '0' ) {
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

This will delete the table as well as the firewall rule.

If called prior to calling init, this will error. It won't check if it has been
inited or not.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	$self->{frontend_obj}->{test_data} = {};

	my @commands;
	push( @commands, 'ipfw table ' . $self->{prefix} . '_' . $self->{name} . ' destroy' );
	push( @commands, 'ipfw delete ' . $self->{options}{rule} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item  2>&1`;
			if ( $? ne '0' ) {
				$self->{error} = 17;
				$self->{errorString}
					= 'teardown failed. non-zero exit code for the command... "' . $item . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]
} ## end sub teardown

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

Backend has not been initted yet.

=head2 2, invalidPortSpecified

Port is either not a positive int or a name that can be resolved by getservbyname.

=head2 3, portsNotArray

The data passed to new for ports is not an array.

=head2 4, protocolsNotArray

The data passed to new for protocols is not an array.

=head2 5, invalidPortSpecified

Port is either not a positive int or a name that can be resolved by getservbyname.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

=head2 8, optionsNotHash

The item passed to new for options is not a hash.

=head2 9, noBanItem

No IP specified to ban.

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

Failed get a list of bans.

=head2 16, reInitFailed

Failed to re_init the backend.

=head2 17, teardownFailed

Failed to teardown the backend.

=head2 18, alreadyInited

Backend has already been initiated.

=head2 19, ruleInvalid

The specified rule is not a int or 1 or less.

=head2 20, typeInvalid

The value for type is not valid.

=head2 21, unreachInvalid

The value for the uncreach option is invalid. Should be of a
value unstood by unreach for ipfw(8).

=head2 22, unreach6Invalid

The value for the uncreach6 option is invalid. Should be of a
value unstood by unreach6 for ipfw(8).

=head2 23, initFailed

One of the required commands for init failed.

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
