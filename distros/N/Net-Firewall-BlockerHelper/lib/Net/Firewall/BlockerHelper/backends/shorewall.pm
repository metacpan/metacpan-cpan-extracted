package Net::Firewall::BlockerHelper::backends::shorewall;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::shorewall - Shorewall backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'shorewall',
                name    => 'derp',
                options => {
                          type => 'drop',
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

This backend blocks IPs using Shorewall's dynamic blacklisting via the
L<shorewall(8)> and L<shorewall6(8)> commands. IPv4 addresses are handled
by the C<shorewall> command and IPv6 addresses by the C<shorewall6>
command.

Dynamic blacklisting is part of Shorewall itself, so there is nothing to
create at init time. Banning an IP is a matter of running
C<< shorewall <type> <ip> >> and unbanning is a matter of running
C<< shorewall allow <ip> >>.

This does require the firewall to actually be in the started state and
DYNAMIC_BLACKLIST to not have been set to C<No> in L<shorewall.conf(5)>. It
is enabled by default, so unless it has been explicitly disabled there is
nothing to configure.

Requires C<shorewall> and, for IPv6 support, C<shorewall6> to be installed
and in the C<PATH> of the process, which must have sufficient privileges to
run them.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: A hash of options to pass to the backend. See below for further info.
        Default :: {}

    - ports :: Not used by this backend but accepted for parity with the others.
        Default :: []

    - protocols :: Not used by this backend but accepted for parity with the others.
        Default :: []

    - prefix :: Prefix to use.
        Default :: kur

    - name :: Name of this specific instance.
        Default :: undef

The options hash accepts the following.

    - shorewall_cmd :: Path to the shorewall binary, used for IPv4 addresses.
        Default :: shorewall

    - shorewall6_cmd :: Path to the shorewall6 binary, used for IPv6 addresses.
        Default :: shorewall6

    - type :: The block method to use. One of 'drop' or 'reject'.
                - drop   :: Silently drop the packet.
                - reject :: Send an ICMP port-unreachable back.
        Default :: drop

All errors are considered fatal, meaning if new fails it will die.

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'shorewall',
                name    => 'ssh',
                options => { type => 'drop' },
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
				20 => 'typeInvalid',
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
			shorewall_cmd  => 'shorewall',
			shorewall6_cmd => 'shorewall6',
			type           => 'drop',
		},
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

	if ( defined( $opts{prefix} ) ) {
		$self->{prefix} = $opts{prefix};
	}

	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
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

		if ( !defined( $opts{options}{shorewall_cmd} ) ) {
			$self->{options}{shorewall_cmd} = 'shorewall';
		}
		if ( !defined( $opts{options}{shorewall6_cmd} ) ) {
			$self->{options}{shorewall6_cmd} = 'shorewall6';
		}

		my %valid_types = ( drop => 1, reject => 1 );

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
				= '$opts{options}{type} is "' . $opts{options}{type} . '" and not one of "drop" or "reject"';
			$self->warn;
		} elsif ( !defined( $opts{options}{type} ) ) {
			$self->{options}{type} = 'drop';
		}
	} ## end if ( defined( $opts{options} ) )

	return $self;
} ## end sub new

# Internal helper. Picks which of the two shorewall binaries to run for the
# passed IP.
#
# Shorewall splits IPv4 and IPv6 across two separate programs with separate
# configuration and separate dynamic blacklists, so unlike the backends that
# pass a family flag to a single binary, here the family decides which command
# is invoked. Handing an IPv6 address to shorewall rather than shorewall6
# would be rejected, so this choice has to be made for every ban and unban.
#
# Args:
#
#     ip - The address the command will act on, as a plain string. Expected to
#          be an already validated and lowercased IPv4 or IPv6 address. The
#          family is decided by matching against $IPv4_re, so anything that is
#          not valid IPv4 is treated as IPv6.
#
# Returns the command as a plain string, from either the shorewall_cmd option,
# 'shorewall' by default, or the shorewall6_cmd option, 'shorewall6' by
# default. Only the program is returned; the subcommand and the address are
# appended by the caller.
#
#     $self->_cmd_for('10.0.0.1');      # shorewall
#     $self->_cmd_for('2001:db8::1');   # shorewall6
#
#     # as used when building a ban
#     my $command = $self->_cmd_for($ip) . ' drop ' . $ip;
sub _cmd_for {
	my ( $self, $ip ) = @_;

	if ( $ip =~ /\A$IPv4_re\z/ ) {
		return $self->{options}{shorewall_cmd};
	}
	return $self->{options}{shorewall6_cmd};
}

=head2 init

Initiates the backend.

Dynamic blacklisting is part of Shorewall itself, so there is nothing to
create.

Note that for bans to have an effect the firewall must be started and
DYNAMIC_BLACKLIST must not have been disabled in shorewall.conf. See
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

	# dynamic blacklisting is always available, so there are no commands to run
	my @commands;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then C<< shorewall <type> <ip> >> is run, using
C<shorewall6> for IPv6 addresses. Banning an already banned IP is a noop.

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

	my $command = $self->_cmd_for( $opts{ban} ) . ' ' . $self->{options}{type} . ' ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		# backticks give undef when the command could not be executed at all
		if ( !defined($output) ) {
			$output = 'no output, the command could not be executed... ' . $!;
		}
		if ( $? != 0 ) {
			$self->{error} = 13;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then C<< shorewall allow <ip> >> is run, using C<shorewall6>
for IPv6 addresses. Unbanning an IP that is not banned is a noop.

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

	my $command = $self->_cmd_for( $opts{ban} ) . ' allow ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		# backticks give undef when the command could not be executed at all
		if ( !defined($output) ) {
			$output = 'no output, the command could not be executed... ' . $!;
		}
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

Bans a CIDR range. Shorewall's dynamic blacklisting accepts a network prefix
in the same manner as a single address, so this runs
C<< shorewall <type> <cidr> >>, using C<shorewall6> for IPv6 ranges. The
value of ban is validated as being a IPv4 or IPv6 CIDR range and lowercased.
Banning an already banned range is a noop.

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

	my $command = $self->_cmd_for_cidr( $opts{ban} ) . ' ' . $self->{options}{type} . ' ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		# backticks give undef when the command could not be executed at all
		if ( !defined($output) ) {
			$output = 'no output, the command could not be executed... ' . $!;
		}
		if ( $? != 0 ) {
			$self->{error} = 26;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by running C<< shorewall allow <cidr> >>, using
C<shorewall6> for IPv6 ranges. The value of ban is validated as being a
IPv4 or IPv6 CIDR range and lowercased. Unbanning a range that is not
banned is a noop.

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

	my $command = $self->_cmd_for_cidr( $opts{ban} ) . ' allow ' . $opts{ban};

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		# backticks give undef when the command could not be executed at all
		if ( !defined($output) ) {
			$output = 'no output, the command could not be executed... ' . $!;
		}
		if ( $? != 0 ) {
			$self->{error} = 27;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
		}
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

# Internal helper. The CIDR counterpart of _cmd_for: picks which of the two
# shorewall binaries to run for the passed range.
#
# A separate sub rather than a wider _cmd_for because the family has to be
# read off the address portion of the range, not off the whole string. A range
# always holds a "/" and a prefix length, which would never match the IPv4
# regexp, so passing a range straight to _cmd_for would silently select
# shorewall6 for every range including IPv4 ones.
#
# Args:
#
#     cidr - The range the command will act on, as a plain string. Expected to
#            be an already validated CIDR range such as "10.0.0.0/8" or
#            "2001:db8::/32". The address is split off at the "/" and matched
#            against $IPv4_re; anything that does not parse as a range with an
#            IPv4 address, including a bare address with no prefix, is treated
#            as IPv6.
#
# Returns the command as a plain string, from either the shorewall_cmd option,
# 'shorewall' by default, or the shorewall6_cmd option, 'shorewall6' by
# default. Only the program is returned; the subcommand and the range are
# appended by the caller.
#
#     $self->_cmd_for_cidr('10.0.0.0/8');      # shorewall
#     $self->_cmd_for_cidr('2001:db8::/32');   # shorewall6
sub _cmd_for_cidr {
	my ( $self, $cidr ) = @_;

	if ( $cidr =~ m!\A(.+)/[0-9]{1,3}\z! && $1 =~ /\A$IPv4_re\z/ ) {
		return $self->{options}{shorewall_cmd};
	}
	return $self->{options}{shorewall6_cmd};
}

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

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from; init cleans up any remnants
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @to_ban      = keys( %{ $self->{banned} } );
	my @to_ban_cidr = keys( %{ $self->{banned_cidr} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $command = $self->_cmd_for($item) . ' ' . $self->{options}{type} . ' ' . $item;

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			# backticks give undef when the command could not be executed at all
			if ( !defined($output) ) {
				$output = 'no output, the command could not be executed... ' . $!;
			}
			if ( $? != 0 ) {
				$self->{error} = 13;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item (@to_ban)

	foreach my $item (@to_ban_cidr) {
		my $command = $self->_cmd_for_cidr($item) . ' ' . $self->{options}{type} . ' ' . $item;

		if ( $self->{testing} ) {
			push( @re_init_test_data, $command );
		} else {
			my $output = `$command 2>&1`;
			# backticks give undef when the command could not be executed at all
			if ( !defined($output) ) {
				$output = 'no output, the command could not be executed... ' . $!;
			}
			if ( $? != 0 ) {
				$self->{error} = 26;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item (@to_ban_cidr)

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup for the backend.

This will C<allow> every currently banned IP and CIDR range. The internal
list of bans is kept, so a following re_init will re-add them.

    $fw_helper->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		push( @commands, $self->_cmd_for($item) . ' allow ' . $item );
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		push( @commands, $self->_cmd_for_cidr($item) . ' allow ' . $item );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			# backticks give undef when the command could not be executed at all
			if ( !defined($output) ) {
				$output = 'no output, the command could not be executed... ' . $!;
			}
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

    $fw_helper->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Runs C<< shorewall show dynamic >>, and, when anything IPv6 is currently
banned, C<< shorewall6 show dynamic >> as well. A zero exit code from each
is treated as healthy. The IPv6 side is only checked when in use so setups
without shorewall6 installed are not flagged as unhealthy. This is the
equivalent of fail2ban's C<actioncheck>.

    if ( !$fw_helper->check ) {
        $fw_helper->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# the IPv4 side is always checked; the IPv6 side only when something
	# IPv6 is actually banned, as _cmd_for/_cmd_for_cidr only ever return
	# shorewall6_cmd for IPv6 items
	my %cmds = ( $self->{options}{shorewall_cmd} => 1 );
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		$cmds{ $self->_cmd_for($item) } = 1;
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		$cmds{ $self->_cmd_for_cidr($item) } = 1;
	}
	my @commands = map { $_ . ' show dynamic' } sort( keys(%cmds) );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
		return 1;
	}

	foreach my $command (@commands) {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			return 0;
		}
	}

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by C<allow>ing each
of them and forgetting them. This is the equivalent of fail2ban's
C<actionflush>.

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

	my @commands;
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		push( @commands, $self->_cmd_for($item) . ' allow ' . $item );
	}
	foreach my $item ( keys( %{ $self->{banned_cidr} } ) ) {
		push( @commands, $self->_cmd_for_cidr($item) . ' allow ' . $item );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
			# backticks give undef when the command could not be executed at all
			if ( !defined($output) ) {
				$output = 'no output, the command could not be executed... ' . $!;
			}
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

=head2 20, typeInvalid

The option type is not 'drop' or 'reject'.

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
