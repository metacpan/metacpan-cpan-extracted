package Net::Firewall::BlockerHelper::backends::routeros;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::routeros - MikroTik RouterOS backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend=>'routeros',
                name=>'ssh',
                options=>{
                          host     => '192.0.2.1',
                          user     => 'admin',
                          identity => '/home/user/.ssh/id_ed25519',
                          },
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

    $fw_helper->init_backend;

    $fw_helper->ban(ban => '5.6.7.8');
    $fw_helper->ban(ban => '1.2.3.4');

    $fw_helper->unban(ban => '5.6.7.8');

    $fw_helper->teardown;

=head1 DESCRIPTION

This backend blocks IPs on a MikroTik RouterOS device by driving its CLI
over SSH.

For each instance two address-lists are used, one for IPv4 (default
C<< <prefix>_<name> >> under the C</ip firewall> menu) and one for IPv6
(default C<< <prefix>_<name> >> under the C</ipv6 firewall> menu). A
filter rule in the C<input> chain references each address-list and applies
the configured action. Banning an IP is then simply a matter of adding it
to the relevant address-list.

The filter rules are created via a plain C<add>, which appends them to the
end of the C<input> chain. As RouterOS filter rules are evaluated first
match wins, any earlier rule accepting the traffic will win out over them,
so on a router with the likes of a broad accept rule in C<input> the rules
will need to be moved up the chain for bans to actually take effect. Also,
being in the C<input> chain, they only cover traffic to the router itself
and not traffic forwarded through it.

Requires an SSH client in the C<PATH> of the process and credentials that
allow the configured user to run firewall commands on the router.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: A hash of options to pass to the backend.
        Default :: {}

    - ports :: Not used by this backend.
        Default :: []

    - protocols :: Not used by this backend.
        Default :: []

    - prefix :: Prefix to use.
        - default :: kur

    - name :: Name of this specific instance.
        - default :: undef

The options hash accepts the following.

    - host :: Router hostname or IP. This must be specified.
        - Default :: undef

    - user :: SSH user to connect as.
        - Default :: admin

    - ssh_cmd :: SSH binary plus any base arguments.
        - Default :: ssh

    - ssh_port :: Optional SSH port. When set, '-p <port>' is added.
        - Default :: undef

    - identity :: Optional path to a SSH private key. When set, '-i <identity>'
            is added.
        - Default :: undef

    - list4 :: IPv4 address-list name.
        - Default :: <prefix>_<name>

    - list6 :: IPv6 address-list name.
        - Default :: <prefix>_<name>

    - action :: Firewall action for the drop rules.
        - Default :: drop

All errors are considered fatal, meaning if new fails it will die.

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend=>'routeros',
                name=>'ssh',
                options=>{ host => '192.0.2.1' },
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
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'hostNotDefined',
				31 => 'banCidrFailed',
				32 => 'unbanCidrFailed',
				33 => 'cidrItemNotCidr',
				34 => 'cidrNotSupported',
				35 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		backend      => undef,
		options      => {},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		name         => undef,
		frontend_obj => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
	};
	bless $self;

	# used internally for testing
	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}

	if ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
	}

	if ( defined( $opts{options} ) ) {
		if ( ref( $opts{options} ) ne 'HASH' ) {
			$self->{perror}      = 1;
			$self->{error}       = 8;
			$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
			$self->warn;
		}
		$self->{options} = $opts{options};
	}

	# host is required
	if ( !defined( $self->{options}{host} )
		|| $self->{options}{host} eq '' )
	{
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'host is not defined or is blank';
		$self->warn;
	}

	# fill in the defaults for anything not specified
	if ( !defined( $self->{options}{user} ) ) {
		$self->{options}{user} = 'admin';
	}
	if ( !defined( $self->{options}{ssh_cmd} ) ) {
		$self->{options}{ssh_cmd} = 'ssh';
	}
	if ( !defined( $self->{options}{action} ) ) {
		$self->{options}{action} = 'drop';
	}
	if ( !defined( $self->{options}{list4} ) ) {
		$self->{options}{list4} = $self->{prefix} . '_' . ( defined( $self->{name} ) ? $self->{name} : '' );
	}
	if ( !defined( $self->{options}{list6} ) ) {
		$self->{options}{list6} = $self->{prefix} . '_' . ( defined( $self->{name} ) ? $self->{name} : '' );
	}

	return $self;
} ## end sub new

# Internal helper. Returns the SSH command prefix string built from the
# ssh_cmd, ssh_port, identity, user, and host options, e.g.
# "ssh -p 22 -i /key admin@host".
sub _ssh {
	my ($self) = @_;

	my $ssh = $self->{options}{ssh_cmd};

	if ( defined( $self->{options}{ssh_port} )
		&& $self->{options}{ssh_port} ne '' )
	{
		$ssh .= ' -p ' . $self->{options}{ssh_port};
	}

	if ( defined( $self->{options}{identity} )
		&& $self->{options}{identity} ne '' )
	{
		$ssh .= ' -i ' . $self->{options}{identity};
	}

	$ssh .= ' ' . $self->{options}{user} . '@' . $self->{options}{host};

	return $ssh;
} ## end sub _ssh

# Internal helper. Given a RouterOS CLI line, returns the full command to
# run it over SSH, e.g. <_ssh> '<routeros_cli>'.
sub _remote {
	my ( $self, $routeros_cli ) = @_;

	return $self->_ssh . " '" . $routeros_cli . "'";
}

=head2 init

Initiates the backend. Over SSH this runs C</ip firewall filter add> and
C</ipv6 firewall filter add> to create a filter rule in the C<input> chain
for each family, matching its address-list and applying the configured
action.

Note that the rules are appended to the end of the C<input> chain, so they
may need moving up past any earlier accept rules to have an effect. See
L</DESCRIPTION>.

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

	my $list4  = $self->{options}{list4};
	my $list6  = $self->{options}{list6};
	my $action = $self->{options}{action};

	my @commands = (
		$self->_remote(
			'/ip firewall filter add chain=input src-address-list=' . $list4 . ' action=' . $action ),
		$self->_remote(
			'/ipv6 firewall filter add chain=input src-address-list=' . $list6 . ' action=' . $action ),
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 12;
				$self->{errorString} = 'Init failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the relevant address-list by running
C</ip firewall address-list add> or C</ipv6 firewall address-list add>
over SSH. Banning an already banned IP is a noop.

    $fw_helper->ban(ban => $ip);

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

	my $command;
	if ( $opts{ban} =~ /\A$IPv4_re\z/ ) {
		$command = $self->_remote(
			'/ip firewall address-list add list=' . $self->{options}{list4} . ' address=' . $opts{ban} );
	} else {
		$command = $self->_remote(
			'/ipv6 firewall address-list add list=' . $self->{options}{list6} . ' address=' . $opts{ban} );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 13;
			$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then its address-list entry is removed by running
C<< /ip firewall address-list remove [find ...] >> or the IPv6 equivalent
over SSH. Unbanning an IP that is not banned is a noop.

    $fw_helper->unban(ban => $ip);

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

	my $command;
	if ( $opts{ban} =~ /\A$IPv4_re\z/ ) {
		$command = $self->_remote( '/ip firewall address-list remove [find where list='
				. $self->{options}{list4}
				. ' address='
				. $opts{ban}
				. ']' );
	} else {
		$command = $self->_remote( '/ipv6 firewall address-list remove [find where list='
				. $self->{options}{list6}
				. ' address='
				. $opts{ban}
				. ']' );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 14;
			$self->{errorString} = 'Unban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

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

Bans a CIDR range by adding it to the relevant address-list. RouterOS
address-lists accept a network prefix in the same manner as a single
address. The value of ban is validated as being a IPv4 or IPv6 CIDR range
and lowercased. Banning an already banned range is a noop.

    $fw_helper->ban_cidr(ban => '1.2.3.0/24');

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
		$self->{error}       = 33;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 33;
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

	my $command;
	if ( $opts{ban} =~ m!\A$IPv4_re/! ) {
		$command = $self->_remote(
			'/ip firewall address-list add list=' . $self->{options}{list4} . ' address=' . $opts{ban} );
	} else {
		$command = $self->_remote(
			'/ipv6 firewall address-list add list=' . $self->{options}{list6} . ' address=' . $opts{ban} );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 31;
			$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the relevant address-list via
C<< address-list remove [find ...] >> over SSH. The value of ban is
validated as being a IPv4 or IPv6 CIDR range and lowercased. Unbanning a
range that is not banned is a noop.

    $fw_helper->unban_cidr(ban => '1.2.3.0/24');

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
		$self->{error}       = 33;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 33;
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

	my $command;
	if ( $opts{ban} =~ m!\A$IPv4_re/! ) {
		$command = $self->_remote( '/ip firewall address-list remove [find where list='
				. $self->{options}{list4}
				. ' address='
				. $opts{ban}
				. ']' );
	} else {
		$command = $self->_remote( '/ipv6 firewall address-list remove [find where list='
				. $self->{options}{list6}
				. ' address='
				. $opts{ban}
				. ']' );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error}       = 32;
			$self->{errorString} = 'Unban failed... command "' . $command . '" resulted in... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges. Single IPs are not included; for those see L</list>.

    my @banned_cidrs = $fw_helper->list_cidr;

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

    my @banned = $fw_helper->list;

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
re-add all previously added bans.

    $fw_helper->re_init;

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

	my @to_re_ban      = keys( %{ $self->{banned} } );
	my @to_re_ban_cidr = keys( %{ $self->{banned_cidr} } );

	my @re_init_test_data;
	foreach my $item (@to_re_ban) {
		my $command;
		if ( $item =~ /\A$IPv4_re\z/ ) {
			$command = $self->_remote(
				'/ip firewall address-list add list=' . $self->{options}{list4} . ' address=' . $item );
		} else {
			$command = $self->_remote(
				'/ipv6 firewall address-list add list=' . $self->{options}{list6} . ' address=' . $item );
		}

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 13;
				$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item (@to_re_ban)

	foreach my $item (@to_re_ban_cidr) {
		my $command;
		if ( $item =~ m!\A$IPv4_re/! ) {
			$command = $self->_remote(
				'/ip firewall address-list add list=' . $self->{options}{list4} . ' address=' . $item );
		} else {
			$command = $self->_remote(
				'/ipv6 firewall address-list add list=' . $self->{options}{list6} . ' address=' . $item );
		}

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 31;
				$self->{errorString} = 'Ban failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item (@to_re_ban_cidr)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

This will remove the filter rules and all address-list entries for both
families.

    $fw_helper->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my $list4 = $self->{options}{list4};
	my $list6 = $self->{options}{list6};

	my @commands = (
		$self->_remote( '/ip firewall filter remove [find where src-address-list=' . $list4 . ']' ),
		$self->_remote( '/ipv6 firewall filter remove [find where src-address-list=' . $list6 . ']' ),
		$self->_remote( '/ip firewall address-list remove [find where list=' . $list4 . ']' ),
		$self->_remote( '/ipv6 firewall address-list remove [find where list=' . $list6 . ']' ),
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 17;
				$self->{errorString} = 'Teardown failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]
} ## end sub teardown

=head2 stop

Alias for L</teardown>, provided for parity with the fail2ban C<actionstop>
concept.

    $fw_helper->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Runs a remote C<< /ip firewall filter print >> for the IPv4 address-list. A
zero exit code is treated as healthy. This is the equivalent of fail2ban's
C<actioncheck>.

    if ( !$fw_helper->check ) {
        $fw_helper->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $command
		= $self->_remote( '/ip firewall filter print where src-address-list=' . $self->{options}{list4} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
		return 1;
	}

	my $output = `$command 2>&1`;
	return $? == 0 ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by removing every entry from both
address-lists, leaving the filter rules in place. This is the equivalent of
fail2ban's C<actionflush>.

    $fw_helper->flush;

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

	my $list4 = $self->{options}{list4};
	my $list6 = $self->{options}{list6};

	my @commands = (
		$self->_remote( '/ip firewall address-list remove [find where list=' . $list4 . ']' ),
		$self->_remote( '/ipv6 firewall address-list remove [find where list=' . $list6 . ']' ),
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 25;
				$self->{errorString} = 'Flush failed... command "' . $command . '" resulted in... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	# the address-list removals above clear both single IP and CIDR entries at once
	$self->{banned}      = {};
	$self->{banned_cidr} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

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

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, banCidrFailed

Failed to ban the CIDR range.

=head2 32, unbanCidrFailed

Failed to unban the CIDR range.

=head2 33, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 34, cidrNotSupported

The backend does not support CIDR bans.

=head2 35, listCidrFailed

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
