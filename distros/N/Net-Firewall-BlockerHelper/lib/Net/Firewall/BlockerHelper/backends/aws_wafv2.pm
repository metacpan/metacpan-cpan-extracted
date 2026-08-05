package Net::Firewall::BlockerHelper::backends::aws_wafv2;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::aws_wafv2 - AWS WAFv2 IP set backend via the aws CLI.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'aws_wafv2',
        name    => 'ssh',
        options => {
            scope => 'REGIONAL',
            name4 => 'blocklist-v4',
            id4   => 'aaaa-bbbb',
            name6 => 'blocklist-v6',
            id6   => 'cccc-dddd',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs by maintaining the addresses of AWS WAFv2 IP sets, using the C<aws>
CLI. A WAF rule referencing the IP set(s) then blocks the traffic.

A WAFv2 IP set holds a single address family, so this backend manages up to
two of them: an IPv4 set (C<name4>/C<id4>) and an IPv6 set (C<name6>/C<id6>).
Banning an address of a family whose set is not configured is an error.

Updating an IP set is a two step operation: a C<get-ip-set> to obtain the
current C<LockToken>, then an C<update-ip-set> supplying the full desired
address list plus that token (WAFv2 uses optimistic locking). The full banned
set for the family is rendered on every change.

This backend manages only the IP set contents; the IP set(s) and the WAF rule
and Web ACL referencing them must already exist. The Web ACL must also be
associated with the resources to be protected, ALBs, API Gateways, and the
like for REGIONAL or the distribution for CLOUDFRONT, as a Web ACL nothing
uses blocks nothing.

Requires the C<aws> CLI in the C<PATH>, configured with credentials able to
get and update the IP sets.

=head1 METHODS

=head2 new

    - options :: Backend specific options. See below.
    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.

The options hash accepts the following.

    - aws_cmd :: Path to the aws binary.
        - Default :: aws

    - scope :: WAFv2 scope, 'REGIONAL' or 'CLOUDFRONT'.
        - Default :: REGIONAL

    - region :: Optional region; appended as --region when set.
        - Default :: undef

    - name4 / id4 :: Name and id of the IPv4 IP set.
        - Default :: undef

    - name6 / id6 :: Name and id of the IPv6 IP set.
        - Default :: undef

At least the family being banned must have both its name and id set.

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
			all_fatal => 1,
			flags     => {
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
				20 => 'scopeInvalid',
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'ipsetNotConfigured',
				31 => 'banCidrFailed',
				32 => 'unbanCidrFailed',
				33 => 'cidrItemNotCidr',
				34 => 'cidrNotSupported',
				35 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options        => {},
		ports          => [],
		protocols      => [],
		testing        => undef,
		test_data      => undef,
		prefix         => 'kur',
		name           => undef,
		frontend_obj   => undef,
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
	};
	bless $self;

	if ( defined( $opts{testing} ) ) {
		$self->{testing} = $opts{testing};
	}
	if ( defined( $opts{frontend_obj} ) ) {
		$self->{frontend_obj} = $opts{frontend_obj};
	}
	if ( defined( $opts{name} ) ) {
		$self->{name} = $opts{name};
	}

	if ( defined( $opts{options} ) && ref( $opts{options} ) ne 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 8;
		$self->{errorString} = 'ref for options is "' . ref( $opts{options} ) . '" and not HASH';
		$self->warn;
	} elsif ( defined( $opts{options} ) ) {
		$self->{options} = $opts{options};
	}

	$self->{options}{aws_cmd} = 'aws'      if ( !defined( $self->{options}{aws_cmd} ) );
	$self->{options}{scope}   = 'REGIONAL' if ( !defined( $self->{options}{scope} ) );

	if ( $self->{options}{scope} ne 'REGIONAL' && $self->{options}{scope} ne 'CLOUDFRONT' ) {
		$self->{perror}      = 1;
		$self->{error}       = 20;
		$self->{errorString} = 'scope is "' . $self->{options}{scope} . '" and not "REGIONAL" or "CLOUDFRONT"';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the trailing --region argument when configured.
sub _region_suffix {
	my ($self) = @_;

	if ( defined( $self->{options}{region} ) && $self->{options}{region} ne '' ) {
		return ' --region ' . $self->{options}{region};
	}
	return '';
}


# Internal helper. Returns the (name, id) pair for family 4 or 6, either of
# which may be undef when not configured.
sub _conf_for_family {
	my ( $self, $fam ) = @_;

	if ( $fam == 4 ) {
		return ( $self->{options}{name4}, $self->{options}{id4} );
	}
	return ( $self->{options}{name6}, $self->{options}{id6} );
}

# Internal helper. True if the given family (4 or 6) has both a name and id.
sub _family_configured {
	my ( $self, $fam ) = @_;

	my ( $name, $id ) = $self->_conf_for_family($fam);
	return ( defined($name) && $name ne '' && defined($id) && $id ne '' ) ? 1 : 0;
}

# Internal helper. Returns the list of configured families (4 and/or 6).
sub _configured_families {
	my ($self) = @_;

	my @families;
	push( @families, 4 ) if ( $self->_family_configured(4) );
	push( @families, 6 ) if ( $self->_family_configured(6) );
	return @families;
}

# Internal helper. Returns the banned IPs and CIDR ranges of the given family,
# sorted, each as a CIDR, space joined. Single IPs are rendered with an explicit
# /32 or /128; banned CIDR ranges are already CIDRs and are emitted as is.
sub _render_family {
	my ( $self, $fam ) = @_;

	my @addresses;
	foreach my $ip ( sort( keys( %{ $self->{banned} } ) ) ) {
		my $is_v4 = ( $ip =~ /\A$IPv4_re\z/ ) ? 1 : 0;
		next if ( $fam == 4 && !$is_v4 );
		next if ( $fam == 6 && $is_v4 );
		push( @addresses, $ip . ( $is_v4 ? '/32' : '/128' ) );
	}

	# banned CIDR ranges live in the same IP set; the address part before the
	# prefix determines the family and the CIDR is used as is
	foreach my $cidr ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		my ($addr) = $cidr =~ m!\A(.+)/[0-9]{1,3}\z!;
		my $is_v4  = ( defined($addr) && $addr =~ /\A$IPv4_re\z/ ) ? 1 : 0;
		next if ( $fam == 4 && !$is_v4 );
		next if ( $fam == 6 && $is_v4 );
		push( @addresses, $cidr );
	}

	return join( ' ', @addresses );
} ## end sub _render_family


# Internal helper. Returns the shared --scope/--name/--id (and --region)
# arguments identifying an IP set.
sub _set_suffix {
	my ( $self, $name, $id ) = @_;

	return ' --scope ' . $self->{options}{scope} . ' --name ' . $name . ' --id ' . $id . $self->_region_suffix;
}

# Internal helper. Returns the get-ip-set command for an IP set.
sub _get_command {
	my ( $self, $name, $id ) = @_;

	return $self->{options}{aws_cmd} . ' wafv2 get-ip-set' . $self->_set_suffix( $name, $id );
}

# Internal helper. Returns the update-ip-set command for an IP set with the
# given rendered addresses and lock token.
sub _update_command {
	my ( $self, $name, $id, $addresses, $token ) = @_;

	return
		  $self->{options}{aws_cmd}
		. ' wafv2 update-ip-set'
		. $self->_set_suffix( $name, $id )
		. ' --addresses '
		. $addresses
		. ' --lock-token '
		. $token;
} ## end sub _update_command

# Internal helper. Applies the current banned state for one family by running a
# get-ip-set then an update-ip-set. In testing it appends the two commands (with
# a <lock-token> placeholder) to the passed accumulator; in real mode it runs the
# get, extracts the LockToken, and runs the update, raising the error flag on
# failure.
sub _apply_family {
	my ( $self, $fam, $error_flag, $acc ) = @_;

	my ( $name, $id ) = $self->_conf_for_family($fam);
	my $addresses = $self->_render_family($fam);
	my $get       = $self->_get_command( $name, $id );

	if ( $self->{testing} ) {
		push( @{$acc}, $get, $self->_update_command( $name, $id, $addresses, '<lock-token>' ) );
		return;
	}

	my $get_out = `$get 2>&1`;
	if ( $? != 0 ) {
		$self->{error}       = $error_flag;
		$self->{errorString} = 'command "' . $get . '" failed... ' . $get_out;
		$self->warn;
		return;
	}

	my ($token) = $get_out =~ /"LockToken"\s*:\s*"([^"]+)"/;
	$token = '' if ( !defined($token) );

	my $update     = $self->_update_command( $name, $id, $addresses, $token );
	my $update_out = `$update 2>&1`;
	if ( $? != 0 ) {
		$self->{error}       = $error_flag;
		$self->{errorString} = 'command "' . $update . '" failed... ' . $update_out;
		$self->warn;
	}

	return;
} ## end sub _apply_family

=head2 init

Initiates the backend. Runs C<aws wafv2 get-ip-set> for each configured IP
set to verify it exists and is reachable, erroring if any of them fail.
Nothing is modified.

Note that for bans to have an effect the Web ACL referencing the IP sets
must be associated with the resources to be protected. See L</DESCRIPTION>.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my @commands;
	foreach my $fam ( $self->_configured_families ) {
		my ( $name, $id ) = $self->_conf_for_family($fam);
		push( @commands, $self->_get_command( $name, $id ) );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $command (@commands) {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error}       = 12;
				$self->{errorString} = 'init failed. command "' . $command . '" failed... ' . $output;
				$self->warn;
			}
		}
	} ## end else [ if ( $self->{testing} ) ]

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the ban list. The IP set for its family is
then updated via a C<get-ip-set> to fetch the current LockToken followed by
an C<update-ip-set> supplying the full banned list for that family, with
single IPs rendered as /32 or /128 CIDRs. Banning an IP whose family has no
IP set configured is an error. Banning an already banned IP is a noop.

    $fw_helper->ban( ban => $ip );

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

	my $fam = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? 4 : 6;
	if ( !$self->_family_configured($fam) ) {
		$self->{error}       = 30;
		$self->{errorString} = 'no IPv' . $fam . ' IP set is configured, cannot ban "' . $opts{ban} . '"';
		$self->warn;
		return;
	}

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned}{ $opts{ban} } = 1;

	my @commands;
	$self->_apply_family( $fam, 13, \@commands );
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the ban list. The IP set for its family is
then rewritten without it via a C<get-ip-set> plus C<update-ip-set> pair.
Unbanning an IP that is not banned is a noop.

    $fw_helper->unban( ban => $ip );

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

	my $fam = ( $opts{ban} =~ /\A$IPv4_re\z/ ) ? 4 : 6;
	delete( $self->{banned}{ $opts{ban} } );

	my @commands;
	$self->_apply_family( $fam, 14, \@commands );
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
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

Bans a CIDR range by adding it to the IP set for its family. WAFv2 IP sets
store CIDR ranges natively, so the range is used as is. The value of ban is
validated as being a IPv4 or IPv6 CIDR and lowercased. Banning a CIDR whose
family has no IP set configured is an error. Banning an already banned CIDR
is a noop.

    $fw_helper->ban_cidr( ban => '1.2.3.0/24' );

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

	my ($addr) = $opts{ban} =~ m!\A(.+)/[0-9]{1,3}\z!;
	my $fam = ( defined($addr) && $addr =~ /\A$IPv4_re\z/ ) ? 4 : 6;
	if ( !$self->_family_configured($fam) ) {
		$self->{error}       = 30;
		$self->{errorString} = 'no IPv' . $fam . ' IP set is configured, cannot ban "' . $opts{ban} . '"';
		$self->warn;
		return;
	}

	if ( $self->{banned_cidr}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;

	my @commands;
	$self->_apply_family( $fam, 31, \@commands );
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by removing it from the IP set for its family, rewriting
the set via a C<get-ip-set> plus C<update-ip-set> pair. The value of ban is
validated as being a IPv4 or IPv6 CIDR and lowercased. Unbanning a CIDR that
is not banned is a noop.

    $fw_helper->unban_cidr( ban => '1.2.3.0/24' );

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

	my ($addr) = $opts{ban} =~ m!\A(.+)/[0-9]{1,3}\z!;
	my $fam = ( defined($addr) && $addr =~ /\A$IPv4_re\z/ ) ? 4 : 6;
	delete( $self->{banned_cidr}{ $opts{ban} } );

	my @commands;
	$self->_apply_family( $fam, 32, \@commands );
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges from internal state; the IP sets are not queried.

    my @banned_cidrs = $fw_helper->list_cidr;

=cut

sub list_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list_cidr';
	}

	return keys( %{ $self->{banned_cidr} } );
} ## end sub list_cidr

=head2 list

List banned IPs. Returns an array of the currently banned single IPs from
internal state; the IP sets are not queried. CIDR ranges are not included;
for those see L</list_cidr>.

    my @banned = $fw_helper->list;

=cut

sub list {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'list';
	}

	return keys( %{ $self->{banned} } );
} ## end sub list

=head2 re_init

Tears down and re-initiates, then re-applies the full retained ban list,
both single IPs and CIDR ranges, to each configured IP set via
C<get-ip-set> plus C<update-ip-set>.

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

	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my @commands;
	foreach my $fam ( $self->_configured_families ) {
		$self->_apply_family( $fam, 13, \@commands );
	}
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Empties each configured IP set by pushing an empty address list via
C<update-ip-set>. The internal ban list is kept so a following re_init
restores it. The IP sets themselves are not deleted.

    $fw_helper->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# render updates against an empty ban set without disturbing the retained
	# lists; both single IPs and CIDR ranges live in the same IP sets
	my %saved      = %{ $self->{banned} };
	my %saved_cidr = %{ $self->{banned_cidr} };
	$self->{banned}      = {};
	$self->{banned_cidr} = {};

	my @commands;
	foreach my $fam ( $self->_configured_families ) {
		$self->_apply_family( $fam, 17, \@commands );
	}

	$self->{banned}      = \%saved;
	$self->{banned_cidr} = \%saved_cidr;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
} ## end sub teardown

=head2 stop

Alias for L</teardown>.

    $fw_helper->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies each configured IP set is still fetchable by running
C<aws wafv2 get-ip-set> against it. Returns 1 if all succeed and 0 if any
fail.

    $result=$fw_helper->check;

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my @commands;
	foreach my $fam ( $self->_configured_families ) {
		my ( $name, $id ) = $self->_conf_for_family($fam);
		push( @commands, $self->_get_command( $name, $id ) );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
		return 1;
	}

	foreach my $command (@commands) {
		my $output = `$command 2>&1`;
		return 0 if ( $? != 0 );
	}

	return 1;
} ## end sub check

=head2 flush

Removes all bans at once by clearing the internal ban lists, both single
IPs and CIDR ranges, and pushing the now empty address list to each
configured IP set via C<update-ip-set>.

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

	# the IP sets are emptied at once, dropping both single IPs and CIDR ranges
	$self->{banned}      = {};
	$self->{banned_cidr} = {};

	my @commands;
	foreach my $fam ( $self->_configured_families ) {
		$self->_apply_family( $fam, 25, \@commands );
	}
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}
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

Failed to init the backend. A get-ip-set for a configured IP set failed.

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

=head2 20, scopeInvalid

The scope option is not either "REGIONAL" or "CLOUDFRONT".

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 30, ipsetNotConfigured

No IP set is configured for the family, IPv4 or IPv6, of the item.

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

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::aws_wafv2
