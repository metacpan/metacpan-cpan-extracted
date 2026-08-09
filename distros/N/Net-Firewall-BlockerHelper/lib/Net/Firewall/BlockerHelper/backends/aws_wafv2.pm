package Net::Firewall::BlockerHelper::backends::aws_wafv2;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::aws_wafv2 - AWS WAFv2 IP set backend via the aws CLI.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

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

# Internal helper. Returns the --region argument to append to every aws
# invocation, or nothing when no region is configured.
#
# Emitting the flag only when the option is set is deliberate rather than
# defaulting to a region here. With it left off, the aws CLI falls back to its
# own resolution order, the AWS_REGION environment variable and then the
# profile's configured region, which is what an instance running inside an
# already configured environment wants. Hardcoding a default would silently
# override that.
#
# Note the CLOUDFRONT scope is only served out of us-east-1, so an instance
# using that scope needs either the region option or an environment already
# pointing there.
#
# Takes no arguments.
#
# Returns the argument as a string with a leading space, ready to be
# concatenated onto a command, or the empty string when the region option is
# unset or empty. Never returns undef.
#
#     # with the region option set to us-west-2
#     $self->_region_suffix;    # ' --region us-west-2'
#
#     # with no region configured
#     $self->_region_suffix;    # ''
sub _region_suffix {
	my ($self) = @_;

	if ( defined( $self->{options}{region} ) && $self->{options}{region} ne '' ) {
		return ' --region ' . $self->{options}{region};
	}
	return '';
}


# Internal helper. Returns the configured WAFv2 IP set name and id for one
# address family.
#
# A WAFv2 IP set is single family, created as either IPV4 or IPV6, so blocking
# both means two separate sets on the AWS side. Both a name and an id are
# needed to address one: the aws CLI requires both on every call, as the name
# alone is not unique.
#
# Either family may be left unconfigured, which is how an instance is told to
# handle only IPv4 or only IPv6. That is why this returns whatever is there
# rather than erroring, and why callers go through _family_configured before
# using the result.
#
# Args:
#
#     fam - The address family, as the number 4 or 6. Anything other than 4 is
#           treated as 6, so this is really a two way branch rather than a
#           validated argument.
#
# Returns a two element list of the name and the id, in that order. Either or
# both may be undef, or set but empty, when that family is not configured.
#
#     my ( $name, $id ) = $self->_conf_for_family(4);
#     #   the name4 and id4 options
#
#     my ( $name, $id ) = $self->_conf_for_family(6);
#     #   the name6 and id6 options, both undef if v6 is not configured
sub _conf_for_family {
	my ( $self, $fam ) = @_;

	if ( $fam == 4 ) {
		return ( $self->{options}{name4}, $self->{options}{id4} );
	}
	return ( $self->{options}{name6}, $self->{options}{id6} );
}

# Internal helper. Says whether one address family has a usable IP set
# configured, meaning both a name and an id are present and non empty.
#
# Both are required because the aws CLI needs both to address a set; having
# only one is as useless as having neither and is treated the same way. This
# is the guard every code path goes through before touching a family, so a
# half configured family is skipped rather than producing a command with an
# empty --name or --id that AWS would reject.
#
# Args:
#
#     fam - The address family, as the number 4 or 6. Anything other than 4 is
#           treated as 6.
#
# Returns 1 when that family has both a name and an id set to something non
# empty, 0 otherwise. Always one of those two values, never undef.
#
#     # with name4 and id4 both set
#     $self->_family_configured(4);    # 1
#
#     # with neither name6 nor id6 set
#     $self->_family_configured(6);    # 0
#
#     # with name6 set but id6 missing: still not usable
#     $self->_family_configured(6);    # 0
sub _family_configured {
	my ( $self, $fam ) = @_;

	my ( $name, $id ) = $self->_conf_for_family($fam);
	return ( defined($name) && $name ne '' && defined($id) && $id ne '' ) ? 1 : 0;
}

# Internal helper. Returns which address families this instance actually has
# IP sets for, which is what every operation loops over.
#
# Because a WAFv2 IP set is single family and either family may be left
# unconfigured, there is no fixed set of things to act on: an instance may
# manage one set or two. Rather than have init, ban, unban, teardown, and the
# rest each work that out, they all iterate over this.
#
# Takes no arguments.
#
# Returns the families as a list of the numbers 4 and 6, in that order,
# containing only those that are fully configured. May be a single element,
# and may be empty if neither family is configured, though new rejects that
# case so it should not arise in practice.
#
#     # with both families configured
#     my @families = $self->_configured_families;    # ( 4, 6 )
#
#     # with only IPv4 configured
#     my @families = $self->_configured_families;    # ( 4 )
#
#     # the usual shape at the call sites
#     foreach my $fam ( $self->_configured_families ) {
#         $self->_apply_family( $fam, 13, \@commands );
#     }
sub _configured_families {
	my ($self) = @_;

	my @families;
	push( @families, 4 ) if ( $self->_family_configured(4) );
	push( @families, 6 ) if ( $self->_family_configured(6) );
	return @families;
}

# Internal helper. Renders the current bans belonging to one address family
# into the address list that update-ip-set takes.
#
# WAFv2 IP sets are replace-in-full rather than incremental: there is no add
# or remove one address call, so every ban and unban rewrites the entire set
# from the internal state. That is what this produces.
#
# Everything is emitted as CIDR, since that is the only form WAFv2 accepts. A
# single address therefore gets an explicit host prefix appended, /32 or /128
# by family. Banned ranges already carry a prefix and go out as they are.
#
# Single addresses and ranges are pulled from two separate internal lists but
# land in the same set, since AWS does not distinguish them. The two are
# emitted as two sorted runs rather than one merged sorted list, so the
# addresses come first and the ranges after. That is stable, which is what
# matters for the test_data comparisons, just not globally sorted.
#
# The family of a range is decided from the address portion before the prefix,
# because a range always holds a "/" that would never match the IPv4 regexp.
#
# Args:
#
#     fam - The address family to render, as the number 4 or 6. Entries of the
#           other family are skipped. Anything other than 4 behaves as 6.
#
# Returns the addresses as a single space joined string, ready to follow
# --addresses on the command line. Returns the empty string when nothing of
# that family is banned, which is the correct way to empty a WAFv2 IP set and
# is what teardown and flush rely on.
#
#     # with 10.0.0.1 and 10.0.0.0/8 banned
#     $self->_render_family(4);      # '10.0.0.1/32 10.0.0.0/8'
#
#     # the same instance, asked for v6
#     $self->_render_family(6);      # ''
#
#     # with 2001:db8::1 banned
#     $self->_render_family(6);      # '2001:db8::1/128'
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


# Internal helper. Returns the arguments that identify one WAFv2 IP set,
# shared by every command that addresses one.
#
# The aws CLI needs all three of scope, name, and id to locate an IP set on
# each call, plus the region when one is configured. Since both get-ip-set and
# update-ip-set take exactly the same identifying arguments, they are built
# once here so the two cannot drift and end up addressing different sets.
#
# Args:
#
#     name - The IP set's name, as a plain string, from the name4 or name6
#            option. Expected to be non empty; callers go through
#            _family_configured first.
#
#     id   - The IP set's id, as a plain string, from the id4 or id6 option.
#            This is the AWS assigned identifier, not something derived from
#            the name. Also expected to be non empty.
#
# Returns the arguments as a single string with a leading space, ready to be
# concatenated onto a command. The scope comes from the scope option, which is
# 'REGIONAL' by default and may also be 'CLOUDFRONT'.
#
#     $self->_set_suffix( 'blocklist-v4', 'a1b2c3d4-...' );
#     #   ' --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-...'
#
#     # with the region option set, it is appended
#     #   ' --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-... --region us-west-2'
sub _set_suffix {
	my ( $self, $name, $id ) = @_;

	return ' --scope ' . $self->{options}{scope} . ' --name ' . $name . ' --id ' . $id . $self->_region_suffix;
}

# Internal helper. Returns the get-ip-set command for one IP set.
#
# This is used for two different things. init runs it to confirm each
# configured set actually exists and is reachable before declaring the backend
# ready, and _apply_family runs it immediately before every write to pick up
# the current lock token, which update-ip-set will not proceed without.
#
# Args:
#
#     name - The IP set's name, as a plain string, from the name4 or name6
#            option.
#
#     id   - The IP set's AWS assigned id, as a plain string, from the id4 or
#            id6 option.
#
# Returns the command as a single string ready to hand to the runner. The aws
# binary comes from the aws_cmd option, 'aws' by default.
#
#     $self->_get_command( 'blocklist-v4', 'a1b2c3d4-...' );
#     #   aws wafv2 get-ip-set --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-...
sub _get_command {
	my ( $self, $name, $id ) = @_;

	return $self->{options}{aws_cmd} . ' wafv2 get-ip-set' . $self->_set_suffix( $name, $id );
}

# Internal helper. Returns the update-ip-set command that writes a rendered
# address list into one IP set.
#
# WAFv2 has no incremental add or remove, so this always replaces the set's
# entire contents. The lock token is AWS's optimistic concurrency control: it
# comes back from get-ip-set, must be passed on the write, and is rejected if
# anything else has modified the set in between. That is what stops two
# processes from each writing back a list based on a stale read.
#
# Args:
#
#     name      - The IP set's name, as a plain string, from the name4 or
#                 name6 option.
#
#     id        - The IP set's AWS assigned id, as a plain string.
#
#     addresses - The complete new contents of the set, as the space joined
#                 CIDR string produced by _render_family. May be the empty
#                 string, which empties the set.
#
#     token     - The lock token from the immediately preceding get-ip-set, as
#                 a plain string. In testing mode callers pass the literal
#                 placeholder '<lock-token>' instead, since no get is run.
#
# Returns the command as a single string ready to hand to the runner.
#
#     $self->_update_command( 'blocklist-v4', 'a1b2c3d4-...',
#         '10.0.0.1/32 10.0.0.0/8', 'abc123' );
#     #   aws wafv2 update-ip-set --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-... --addresses 10.0.0.1/32 10.0.0.0/8 --lock-token abc123
#
#     # emptying the set, as teardown and flush do
#     $self->_update_command( 'blocklist-v4', 'a1b2c3d4-...', '', 'abc123' );
#     #   aws wafv2 update-ip-set --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-... --addresses  --lock-token abc123
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

# Internal helper. Pushes the current bans for one address family out to its
# WAFv2 IP set. This is the only place the AWS side is written, so ban, unban,
# ban_cidr, unban_cidr, re_init, teardown, and flush all funnel through it,
# once per configured family.
#
# Because WAFv2 replaces the set in full and guards writes with a lock token,
# every write is unavoidably two round trips: a get-ip-set to obtain the
# current token, then an update-ip-set carrying it. They have to stay paired,
# which is why this is one helper rather than the callers sequencing them.
#
# The token is scraped out of the get's JSON with a regexp rather than by
# decoding it. A token that cannot be found falls back to the empty string,
# which AWS will reject, so a parse failure surfaces as the update failing
# rather than as a silent write of the wrong thing.
#
# Nothing here dies. A failure of either command sets the error to the passed
# code, sets errorString with the command and its output, and warns.
#
# Args:
#
#     fam        - The address family to apply, as the number 4 or 6. Expected
#                  to be one that _configured_families returned.
#
#     error_flag - The numeric error code to raise on failure, so the error
#                  reads as the operation that triggered the write. Callers
#                  pass the code matching themselves: 13 from ban and re_init,
#                  14 from unban, 31 and 32 from the CIDR paths, 17 from
#                  teardown, and 25 from flush.
#
#     acc        - An arrayref used only in testing mode, to which the two
#                  commands that would have been run are appended. Callers
#                  pass one they later hand to test_data. Ignored entirely
#                  outside testing mode, but still expected to be a valid
#                  arrayref.
#
# Returns nothing, on success and on failure alike. The caller checks the
# error state rather than a return value.
#
#     # from ban, so a failure reads as banFailed
#     my @commands;
#     foreach my $fam ( $self->_configured_families ) {
#         $self->_apply_family( $fam, 13, \@commands );
#     }
#
# In testing mode nothing is run. The two commands are appended to the
# accumulator with the token replaced by the literal placeholder
# '<lock-token>', since there is no get to take a real one from:
#
#     aws wafv2 get-ip-set --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-...
#     aws wafv2 update-ip-set --scope REGIONAL --name blocklist-v4 --id a1b2c3d4-... --addresses 10.0.0.1/32 --lock-token <lock-token>
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
