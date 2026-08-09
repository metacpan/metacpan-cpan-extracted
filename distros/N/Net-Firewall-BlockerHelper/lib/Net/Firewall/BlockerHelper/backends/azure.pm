package Net::Firewall::BlockerHelper::backends::azure;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::azure - Azure NSG backend via the az CLI.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'azure',
        name    => 'ssh',
        options => {
            resource_group => 'my-rg',
            nsg            => 'my-nsg',
            rule           => 'blocklist',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on Azure by maintaining the C<--source-address-prefixes> of a
single deny rule in a Network Security Group, using the C<az> CLI. The full
set of currently banned IPs is rendered into the rule on every change, so
ban/unban are idempotent. Both IPv4 and IPv6 share the one rule.

This backend manages only the rule's source prefixes. The NSG, the inbound
deny security rule, and the NSG's association with the subnets or NICs to be
protected must already exist.

Requires the C<az> CLI in the C<PATH>, logged in with rights to update the
rule.

=head1 NOTES

This backend was written going off the az CLI docs and actual testing is
needed to double check a few things as the exact behavior is not clear.

When the ban list goes empty, as at teardown or flush, the rule update
ends up passing C<--source-address-prefixes> with no value, and whether
the az CLI accepts that or errors needs checking.

=head1 METHODS

=head2 new

Initiates the backend object. Nothing is contacted at this point; that is done by L</init>.

    - options :: Backend specific options. See below.
    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.

The options hash accepts the following.

    - az_cmd :: Path to the az binary.
        - Default :: az

    - resource_group :: Resource group of the NSG. Required.
        - Default :: undef

    - nsg :: Network Security Group name. Required.
        - Default :: undef

    - rule :: Security rule whose source prefixes are managed. Required.
        - Default :: undef

    - subscription :: Optional subscription; appended as --subscription when set.
        - Default :: undef

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
				24 => 'checkFailed',
				25 => 'flushFailed',
				30 => 'resourceGroupNotDefined',
				31 => 'nsgNotDefined',
				32 => 'ruleNotDefined',
				33 => 'banCidrFailed',
				34 => 'unbanCidrFailed',
				35 => 'cidrItemNotCidr',
				36 => 'cidrNotSupported',
				37 => 'listCidrFailed',
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

	if ( !defined( $self->{options}{resource_group} ) || $self->{options}{resource_group} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option resource_group is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{nsg} ) || $self->{options}{nsg} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option nsg is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{rule} ) || $self->{options}{rule} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 32;
		$self->{errorString} = 'the option rule is undef or blank';
		$self->warn;
	}

	$self->{options}{az_cmd} = 'az' if ( !defined( $self->{options}{az_cmd} ) );

	return $self;
} ## end sub new

# Internal helper. Returns the --subscription argument to append to every az
# invocation, or nothing when no subscription is configured.
#
# Emitting the flag only when the option is set is deliberate rather than
# defaulting to one here. With it left off, az uses whichever subscription the
# logged in account has set as its default, which is what an instance running
# in an already configured environment wants. It only needs specifying on a
# host whose account can see several subscriptions and whose default is not
# the right one.
#
# Takes no arguments.
#
# Returns the argument as a string with a leading space, ready to be
# concatenated onto a command, or the empty string when the subscription
# option is unset or empty. Never returns undef.
#
#     # with the subscription option set
#     $self->_suffix;    # ' --subscription sub-123'
#
#     # with no subscription configured
#     $self->_suffix;    # ''
sub _suffix {
	my ($self) = @_;

	if ( defined( $self->{options}{subscription} ) && $self->{options}{subscription} ne '' ) {
		return ' --subscription ' . $self->{options}{subscription};
	}
	return '';
}


# Internal helper. Returns the arguments that identify the NSG security rule
# this instance manages, shared by every command that touches it.
#
# Azure addresses a rule by the three levels it is nested in: the resource
# group holding the network security group, the NSG itself, and the rule
# within it. All three are needed on every call. Since the show and update
# commands take exactly the same identifying arguments, they are built once
# here so the two cannot drift and end up addressing different rules.
#
# Note this backend does not create the rule. The NSG and the rule are
# expected to already exist and to be wired into the NSG's rule ordering by
# whoever set them up; all this backend does is rewrite the rule's source
# prefixes.
#
# Takes no arguments; all three names come from the options.
#
# Returns the arguments as a single string with a leading space, ready to be
# concatenated onto a command. The subscription is not included; that comes
# from _suffix and goes at the end.
#
#     $self->_base;
#     #   ' --resource-group my-rg --nsg-name my-nsg --name blocklist'
sub _base {
	my ($self) = @_;

	return
		  ' --resource-group '
		. $self->{options}{resource_group}
		. ' --nsg-name '
		. $self->{options}{nsg}
		. ' --name '
		. $self->{options}{rule};
} ## end sub _base

# Internal helper. Renders the current bans into the source prefix list that
# the NSG rule update takes.
#
# An NSG rule's source prefixes are replace-in-full: there is no add or remove
# one prefix call, so every ban and unban rewrites the whole list from the
# internal state. That is what this produces.
#
# Everything is emitted as CIDR, so a single address gets an explicit host
# prefix appended, /32 or /128 by family. Banned ranges already carry a prefix
# and go out as they are. Both families go into the same rule, unlike the AWS
# backend where the two are separate objects.
#
# Single addresses and ranges are pulled from two separate internal lists and
# emitted as two sorted runs rather than one merged sorted list, so the
# addresses come first and the ranges after. That is stable, which is what
# matters for the test_data comparisons, just not globally sorted.
#
# Takes no arguments; the bans come from the object's banned and banned_cidr
# hashes.
#
# Returns the prefixes as a single space joined string, ready to follow
# --source-address-prefixes on the command line. Returns the empty string when
# nothing is banned, which is what teardown and flush push out to empty the
# rule.
#
#     # with 10.0.0.1, 2001:db8::1, and 10.0.0.0/8 banned
#     $self->_prefixes;
#     #   '10.0.0.1/32 2001:db8::1/128 10.0.0.0/8'
#
#     # with nothing banned
#     $self->_prefixes;    # ''
sub _prefixes {
	my ($self) = @_;

	my @prefixes;
	foreach my $ip ( sort( keys( %{ $self->{banned} } ) ) ) {
		push( @prefixes, $ip . ( ( $ip =~ /\A$IPv4_re\z/ ) ? '/32' : '/128' ) );
	}
	# CIDR ranges already carry a prefix and are added verbatim
	foreach my $cidr ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		push( @prefixes, $cidr );
	}

	return join( ' ', @prefixes );
} ## end sub _prefixes

# Internal helper. Returns the az command that writes the current bans into
# the NSG rule's source prefixes. This is the command every ban, unban,
# re_init, teardown, and flush ultimately runs.
#
# The rule is rewritten in full each time, since Azure offers no incremental
# prefix add or remove. Note there is no concurrency guard here, unlike the
# AWS backend's lock token: two processes updating the same rule at once will
# each write back a list based on their own state and the last one wins.
#
# Takes no arguments; the rule identity, the prefixes, and the subscription
# are all assembled from the object.
#
# Returns the command as a single string ready to hand to the runner. The az
# binary comes from the az_cmd option, 'az' by default.
#
#     # with 10.0.0.1, 2001:db8::1, and 10.0.0.0/8 banned
#     $self->_update_command;
#     #   az network nsg rule update --resource-group my-rg --nsg-name my-nsg --name blocklist --source-address-prefixes 10.0.0.1/32 2001:db8::1/128 10.0.0.0/8
sub _update_command {
	my ($self) = @_;

	return
		  $self->{options}{az_cmd}
		. ' network nsg rule update'
		. $self->_base
		. ' --source-address-prefixes '
		. $self->_prefixes
		. $self->_suffix;
} ## end sub _update_command

# Internal helper. Returns the az command that confirms the NSG rule exists,
# used by init and by check.
#
# Since this backend creates nothing, the rule existing is the whole of its
# setup, and a rule deleted out from under a running process is the failure
# this detects. init runs it so a misconfigured resource group, NSG, or rule
# name fails immediately rather than at the first ban, and check runs it to
# decide whether the self heal path should re-push the current bans.
#
# Only the exit status is looked at; nothing parses the rule definition that
# comes back.
#
# Takes no arguments.
#
# Returns the command as a single string ready to hand to the runner, whose
# exit status is 0 when the rule is there.
#
#     $self->_show_command;
#     #   az network nsg rule show --resource-group my-rg --nsg-name my-nsg --name blocklist
#
#     # with the subscription option set, it is appended
#     #   az network nsg rule show --resource-group my-rg --nsg-name my-nsg --name blocklist --subscription sub-123
sub _show_command {
	my ($self) = @_;

	return $self->{options}{az_cmd} . ' network nsg rule show' . $self->_base . $self->_suffix;
}

# Internal helper. Runs one az command and turns a non zero exit into an
# error, so the callers do not each repeat the same capture-and-check.
#
# stderr is folded into stdout so that whatever az complained about ends up in
# the errorString rather than being lost to the terminal. The output is only
# used for that; nothing parses it.
#
# Nothing here dies. A failure sets the error to the passed code, sets
# errorString with the command and its output, and warns, leaving the caller
# to check the error state.
#
# Note this does not itself check testing mode despite what the callers'
# structure might suggest. Callers decide whether to run or to record, and
# only call this when actually running.
#
# Args:
#
#     command    - The complete shell command to run, as a plain string,
#                  normally from _update_command or _show_command. Run through
#                  the shell, so it is expected to be already quoted as
#                  needed.
#
#     error_flag - The numeric error code to raise on a non zero exit, so the
#                  error reads as the operation that triggered it rather than
#                  as a generic command failure. Callers pass the code
#                  matching themselves, such as 13 from ban or 17 from
#                  teardown.
#
# Returns nothing, on success and on failure alike.
#
#     # from ban, so a failure reads as banFailed
#     $self->_run( $self->_update_command, 13 );
#
#     # from init, verifying the rule is there
#     $self->_run( $self->_show_command, 12 );
sub _run {
	my ( $self, $command, $error_flag ) = @_;

	my $output = `$command 2>&1`;
	if ( $? != 0 ) {
		$self->{error}       = $error_flag;
		$self->{errorString} = 'command "' . $command . '" failed... ' . $output;
		$self->warn;
	}

	return;
} ## end sub _run

=head2 init

Initiates the backend, verifying the configured security rule exists via
C<az network nsg rule show>. Nothing is created; the NSG and rule must
already exist.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my @commands = ( $self->_show_command );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		$self->_run( $commands[0], 12 );
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the ban list. The full set of banned IPs
(rendered as /32 or /128 prefixes) and CIDR ranges is then pushed to the
rule via C<az network nsg rule update --source-address-prefixes>. Banning
an already banned IP is a noop.

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

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	$self->{banned}{ $opts{ban} } = 1;

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		$self->_run( $command, 13 );
	}
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the ban list. The rule's source prefixes
are re-rendered without it via C<az network nsg rule update>. Unbanning an
IP that is not banned is a noop.

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

	delete( $self->{banned}{ $opts{ban} } );

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		$self->_run( $command, 14 );
	}
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased, then added verbatim to the rule's source prefixes via
C<az network nsg rule update>. Banning an already banned range is a noop.

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
		$self->{error}       = 35;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 35;
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

	$self->{banned_cidr}{ $opts{ban} } = 1;

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		$self->_run( $command, 33 );
	}
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR and lowercased, then the rule's source prefixes are re-rendered
without it via C<az network nsg rule update>. Unbanning a range that is not
banned is a noop.

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
		$self->{error}       = 35;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 35;
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

	delete( $self->{banned_cidr}{ $opts{ban} } );

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		$self->_run( $command, 34 );
	}
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges.

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
the in-memory ban list; the rule is not queried. CIDR ranges are not
included; for those see L</list_cidr>.

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

Tears down (errors ignored) and re-initiates the backend, then re-applies
the full retained set of banned IPs and CIDR ranges to the rule via
C<az network nsg rule update>.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		$self->_run( $command, 13 );
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Empties the rule's source prefixes. The internal ban list is kept so a
following re_init restores them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# render the update with an empty ban set without disturbing the retained
	# lists, so a following re_init restores both single IPs and CIDR ranges
	my %saved      = %{ $self->{banned} };
	my %saved_cidr = %{ $self->{banned_cidr} };
	$self->{banned}      = {};
	$self->{banned_cidr} = {};
	my $command = $self->_update_command;
	$self->{banned}      = \%saved;
	$self->{banned_cidr} = \%saved_cidr;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		$self->_run( $command, 17 );
	}
} ## end sub teardown

=head2 stop

Alias for L</teardown>.

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

Verifies the rule still exists by running C<az network nsg rule show>.
Returns 1 if the command exits zero and 0 otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $command = $self->_show_command;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
		return 1;
	}

	my $output = `$command 2>&1`;
	return $? == 0 ? 1 : 0;
} ## end sub check

=head2 flush

Removes all bans at once by clearing both the single IP and CIDR ban lists
and re-rendering the rule's now empty source prefixes via
C<az network nsg rule update>.

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

	# the rule is re-rendered from both sets, so clear both to empty it
	$self->{banned}      = {};
	$self->{banned_cidr} = {};

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		$self->_run( $command, 25 );
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

=head2 30, resourceGroupNotDefined

The option resource_group is undef or blank.

=head2 31, nsgNotDefined

The option nsg is undef or blank.

=head2 32, ruleNotDefined

The option rule is undef or blank.

=head2 33, banCidrFailed

Failed to ban the CIDR range.

=head2 34, unbanCidrFailed

Failed to unban the CIDR range.

=head2 35, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 36, cidrNotSupported

The backend does not support CIDR bans.

=head2 37, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::azure
