package Net::Firewall::BlockerHelper;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper - Helps with managing firewalls for banning IPs.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    # create a instance named ssh with a ipfw backend for port 22 tcp
    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
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

    # start the backend
    $fw_helper->init_backend;

    # ban some IPs
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');

    # unban a IP
    $fw_helper->unban(ban => '1.2.3.4');

    # get a list of banned IPs
    my @banned = $fw_helper->list;
    foreach my $ip (@banned) {
        print 'Banned IP: '.$ip."\n";
    }

    # teardown the backend, re-init, and re-ban everything
    $fw_helper->re_init;

    # teardown the backend
    $fw_helper->teardown;

=head1 METHODS

=head2 new

Initiates the the object.

    - backend :: The backend to use. This must be specified.
        - Default :: undef

    - options :: Backend specific options that will be passed to the backend unchecked
            outside of making sure it is a hash ref if defined.
        - Default :: {}

    - ports :: A array of ports to block. Checked to make sure they are ints within
            the range 1 to 65535 or a valid service name via getservbyname.
        - Default :: []

    - protocols :: A array of protocols to block. By default will block all. This
            is checked against /etc/protocols via the function getprotobyname.
        - Default :: []

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance.
        - default :: undef

    - self_heal :: Before each ban or unban, verify the firewall setup is
            still present (via the backend's check) and re_init it if it was
            removed externally. This is the fail2ban actioncheck-before-action
            behavior. Adds one check probe per ban/unban. Can be overridden per
            call by passing self_heal to ban/unban.
        - default :: 1

All errors are considered fatal, meaning if new fails it will die.

    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
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
			all_fatal => 1,
			flags     => {
				1  => 'noBackendSpecified',
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
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'banCidrFailed',
				27 => 'unbanCidrFailed',
				28 => 'cidrItemNotCidr',
				29 => 'cidrNotSupported',
				30 => 'listCidrFailed',
				31 => 'commitFailed',
				32 => 'commitNotSupported',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		backend     => undef,
		options     => {},
		ports       => [],
		protocols   => [],
		testing     => undef,
		test_data   => undef,
		prefix      => 'kur',
		name        => undef,
		backend_obj => undef,
		self_heal   => 1,
	};
	bless $self;

	if ( !defined $opts{backend} ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = 'backend is undef';
		$self->warn;
	}
	$self->{backend} = $opts{backend};

	if ( $self->{backend} !~ /^[a-zA-Z0-9\_]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 11;
		$self->{errorString}
			= '"'
			. $self->{backend}
			. '" does not appear to be valid backend, the regexp /^[a-zA-Z0-9\_]+$/ does not match';
		$self->warn;
	}

	if ( defined( $opts{ports} ) && ref( $opts{ports} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'ports is defined and type is not array but "' . ref( $opts{ports} ) . '"';
		$self->warn;
	} elsif ( defined( $opts{ports} ) ) {
		my %ports;
		foreach my $item ( @{ $opts{ports} } ) {
			if ( $item =~ /^[0-9]+$/ && $item >= 1 && $item <= 65535 ) {
				#push( @{ $self->{ports} }, $item );
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
				#push( @{ $self->{ports} }, $port );
			} ## end else [ if ( $item =~ /^[0-9]+$/ && $item >= 1 && ...)]
		} ## end foreach my $item ( @{ $opts{ports} } )
		my @port_keys = keys(%ports);
		@port_keys = sort { $a <=> $b } @port_keys;
		push( @{ $self->{ports} }, @port_keys );
		## end foreach my $item ( @{ $opts{ports} } )
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

	# check-before-ban self healing, on by default
	if ( defined( $opts{self_heal} ) ) {
		$self->{self_heal} = $opts{self_heal} ? 1 : 0;
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

	return $self;
} ## end sub new

=head2 init_backend

Initiates the backend, creating the backend object and running its init. A
failure is raised as backendInitError.

No arguments are taken.

    $fw_helper->init_backend;

=cut

sub init_backend {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	my $backend = 'Net::Firewall::BlockerHelper::backends::' . $self->{backend};
	my $backend_obj;
	eval {
		# runtime module load: translate Foo::Bar -> Foo/Bar.pm and require it.
		# $self->{backend} is already validated /^[a-zA-Z0-9_]+$/ in new, so this path is safe.
		( my $file = $backend ) =~ s{::}{/}g;
		require $file . '.pm';

		$backend_obj = $backend->new(
			options      => $self->{options},
			ports        => $self->{ports},
			protocols    => $self->{protocols},
			testing      => $self->{testing},
			prefix       => $self->{prefix},
			name         => $self->{name},
			frontend_obj => $self,
		);
		$backend_obj->init;
		1;
	} or do {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'Failed to init backend... ' . $@;
		$self->warn;
	};
	# make sure we got something that is defined and is a object of some sort
	if ( !defined($backend_obj) ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'Failed to init backend. Eval did not die, but returned value is undef';
		$self->warn;
	} elsif ( ref($backend_obj) eq '' || ref($backend_obj) eq 'ARRAY' || ref($backend_obj) eq 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 12;
		$self->{errorString} = 'ref($backend_obj) is "' . ref($backend_obj) . '"';
		$self->warn;
	}

	$self->{backend_obj} = $backend_obj;
} ## end sub init_backend

# Internal helper. If self healing is enabled and the backend is inited, asks
# the backend to check that its firewall setup is still present and re_inits it
# if it is not. This is the fail2ban actioncheck-before-action behavior: the
# setup can be torn down out from under a long lived process by a firewall
# restart or by someone flushing the rules by hand, and without this the
# following ban would appear to succeed while adding nothing.
#
# Called at the top of ban, unban, ban_cidr, and unban_cidr, which pass their
# own %opts straight through. Nothing happens at all if self healing is off,
# if no backend has been inited yet, or if the backend's inited flag is false.
#
# Both the check and the re_init are best effort and run inside eval. A check
# that dies is treated as "do not heal" rather than as unhealthy, so a backend
# whose check is broken does not trigger a rebuild on every call. A re_init
# that dies is swallowed here and left for the ban or unban that follows to
# surface, which keeps the error the caller sees tied to the operation they
# actually asked for.
#
# Args:
#
#     %opts - The option hash the calling method received, passed through
#             verbatim. Only the self_heal key is looked at, and only if it
#             exists; it is a per-call override of the object's self_heal
#             setting and is taken as a boolean, so 0 disables healing for
#             this call and 1 forces it on. Every other key is ignored.
#
# Returns nothing. Whether the setup was checked, found unhealthy, or rebuilt
# is deliberately not reported; callers proceed with their ban or unban either
# way.
#
#     # honor the object's self_heal setting
#     $self->_self_heal;
#
#     # inside ban, passing the caller's options through
#     $self->_self_heal(%opts);
#
#     # skip healing for this one call
#     $self->_self_heal( self_heal => 0 );
sub _self_heal {
	my ( $self, %opts ) = @_;

	my $heal = $self->{self_heal};
	$heal = ( $opts{self_heal} ? 1 : 0 ) if ( exists( $opts{self_heal} ) );

	if (   $heal
		&& defined( $self->{backend_obj} )
		&& $self->{backend_obj}->{inited} )
	{
		my $healthy;
		eval { $healthy = $self->{backend_obj}->check; };
		if ( !$@ && !$healthy ) {
			# the setup was removed externally, rebuild it and re-add the bans
			eval { $self->{backend_obj}->re_init; };
		}
	} ## end if ( $heal && defined( $self->{backend_obj...}))

	return;
} ## end sub _self_heal

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then handed to the backend to ban. If self healing is
enabled, the backend setup is checked and restored first. A backend failure
is caught and re-raised as banFailed.

    $fw_helper->ban(ban => $ip);

=cut

sub ban {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

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

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 13;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	$self->_self_heal(%opts);

	eval { $self->{backend_obj}->ban( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 13;
		$self->{errorString} = 'banning item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub ban

=head2 ban_cidr

Bans a CIDR range.

Only backends whose underlying firewall can match on a network prefix support
this. For backends that do not, the cidrNotSupported error is set. See the
individual backends for which support it.

    $fw_helper->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

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

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 26;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	if ( !$self->{backend_obj}->{cidr_supported} ) {
		$self->{error}       = 29;
		$self->{errorString} = 'the "' . $self->{backend} . '" backend does not support CIDR bans';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	$self->_self_heal(%opts);

	eval { $self->{backend_obj}->ban_cidr( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 26;
		$self->{errorString} = 'banning cidr item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub ban_cidr

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then handed to the backend to unban. If self healing is
enabled, the backend setup is checked and restored first. A backend failure
is caught and re-raised as unbanFailed.

    $fw_helper->unban(ban => $ip);

=cut

sub unban {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

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

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 14;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 IP in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	$self->_self_heal(%opts);

	eval { $self->{backend_obj}->unban( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 14;
		$self->{errorString} = 'unbanning item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub unban

=head2 unban_cidr

Unbans a CIDR range.

Only backends whose underlying firewall can match on a network prefix support
this. For backends that do not, the cidrNotSupported error is set.

    $fw_helper->unban_cidr(ban => '1.2.3.0/24');

=cut

sub unban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

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

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 27;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	if ( !$self->{backend_obj}->{cidr_supported} ) {
		$self->{error}       = 29;
		$self->{errorString} = 'the "' . $self->{backend} . '" backend does not support CIDR bans';
		$self->warn;
		return;
	}

	# lowercase so the same IPv6 CIDR in differing cases can't result in duplicate entries
	$opts{ban} = lc( $opts{ban} );

	$self->_self_heal(%opts);

	eval { $self->{backend_obj}->unban_cidr( ban => $opts{ban} ); };
	if ($@) {
		$self->{error}       = 27;
		$self->{errorString} = 'unbanning cidr item,"' . $opts{ban} . '", failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub unban_cidr

=head2 list

List banned IPs. Returns an array of the currently banned single IPs as
reported by the backend. CIDR range bans are not included; for those see
L</list_cidr>.

    my @banned = $fw_helper->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 15;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	my @banned;
	eval { @banned = $self->{backend_obj}->list; };
	if ($@) {
		$self->{error}       = 15;
		$self->{errorString} = 'listing bans failed... ' . $@;
		$self->warn;
		return;
	}

	return @banned;
} ## end sub list

=head2 list_cidr

List banned CIDR ranges. Backends that do not support CIDR bans always return
an empty list.

    my @banned_cidrs = $fw_helper->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 30;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	my @banned;
	eval { @banned = $self->{backend_obj}->list_cidr; };
	if ($@) {
		$self->{error}       = 30;
		$self->{errorString} = 'listing cidr bans failed... ' . $@;
		$self->warn;
		return;
	}

	return @banned;
} ## end sub list_cidr

=head2 re_init

Tells the backend to re-init itself, rebuilding its firewall setup and
re-applying the current ban list. A backend failure is caught and re-raised
as reInitFailed.

The backend does not need to be inited for this to work, so as well as
recovering a setup that was removed externally, this is what brings one back
after a L</teardown> or L</stop>. The ban list is held on the backend object
and survives both, so the bans are re-applied rather than lost.

    $fw_helper->re_init;

    # resuming after a stop
    $fw_helper->stop;
    $fw_helper->re_init;

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 16;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->re_init; };
	if ($@) {
		$self->{error}       = 16;
		$self->{errorString} = 'backend re_init failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub re_init

=head2 teardown

Tells the backend to tear down its firewall setup, the equivalent of
fail2ban's C<actionstop>. The ban list is retained by the backend so a
following L</re_init> restores it. A backend failure is caught and re-raised
as teardownFailed.

    $fw_helper->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 17;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->teardown; };
	if ($@) {
		$self->{error}       = 17;
		$self->{errorString} = 'backend teardown failed... ' . $@;
		$self->warn;
		return;
	}
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

Asks the backend to verify that its firewall setup is still intact. This is
the equivalent of fail2ban's C<actioncheck>. Returns a true value if the
setup is present and a false value if it appears to have been removed (in
which case a L</re_init> is warranted). On an internal error it sets the
error and returns undef.

    if ( !$fw_helper->check ) {
        $fw_helper->re_init;
    }

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 24;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	my $healthy;
	eval { $healthy = $self->{backend_obj}->check; };
	if ($@) {
		$self->{error}       = 24;
		$self->{errorString} = 'backend check failed... ' . $@;
		$self->warn;
		return;
	}

	return $healthy;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once while leaving the firewall rules in
place. This is the equivalent of fail2ban's C<actionflush>. Unlike
L</teardown>, the blocking rules remain active, so new bans work without a
L</re_init>.

    $fw_helper->flush;

=cut

sub flush {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 25;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->flush; };
	if ($@) {
		$self->{error}       = 25;
		$self->{errorString} = 'backend flush failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub flush

=head2 commit

Tells the backend to write out any state it has been holding back from
persistent storage.

Most backends have nothing to hold back, as the firewall they drive is the
only copy of the state, and those do not implement this at all; calling it
for one of them sets the commitNotSupported error.
L<Net::Firewall::BlockerHelper::backends::openwrt> is currently the only
backend that does implement it, where bans are applied to the live nftables
sets straight away but only reach the UCI config, and so the router's flash,
when this is called.

Where a backend does implement it, it is safe to call as often as wanted and
is a noop when there is nothing outstanding. How often it is worth calling is
a trade off between how much of the ban list can be lost and, for a backend
writing to flash, how much wear is acceptable.

    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');
    $fw_helper->commit;

=cut

sub commit {
	my ( $self, %opts ) = @_;

	$self->errorblank;
	$self->{test_data} = undef;

	if ( !defined( $self->{backend_obj} ) ) {
		$self->{error}       = 31;
		$self->{errorString} = 'No backend object present... init_backend has not been called';
		$self->warn;
		return;
	}

	if ( !$self->{backend_obj}->can('commit') ) {
		$self->{error}       = 32;
		$self->{errorString} = 'the "' . $self->{backend} . '" backend does not implement commit';
		$self->warn;
		return;
	}

	eval { $self->{backend_obj}->commit; };
	if ($@) {
		$self->{error}       = 31;
		$self->{errorString} = 'backend commit failed... ' . $@;
		$self->warn;
		return;
	}
} ## end sub commit

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, noBackendSpecified

No backend was specified to use.

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

The selected backend does not support CIDR bans.

=head2 30, listCidrFailed

Failed to get a list of CIDR bans.

=head2 31, commitFailed

Failed to commit the backend's outstanding state.

=head2 32, commitNotSupported

The selected backend does not implement commit, having no state that is held
back from persistent storage.

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Firewall-BlockerHelper>

=item * Search CPAN

L<https://metacpan.org/release/Net-Firewall-BlockerHelper>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper
