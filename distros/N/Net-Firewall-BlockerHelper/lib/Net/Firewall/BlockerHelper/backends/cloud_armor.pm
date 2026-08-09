package Net::Firewall::BlockerHelper::backends::cloud_armor;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::cloud_armor - Google Cloud Armor backend via the gcloud CLI.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'cloud_armor',
        name    => 'ssh',
        options => {
            policy   => 'my-policy',
            priority => 1000,
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs with Google Cloud Armor by maintaining the C<--src-ip-ranges> of a
single deny rule (identified by its priority) in a security policy, using the
C<gcloud> CLI. The full set of currently banned IPs is rendered into the rule
on every change, so ban/unban are idempotent. Both IPv4 and IPv6 share the one
rule.

Cloud Armor caps the source ranges of a rule, ten per match condition at the
time of writing, so bans past that limit will fail. A failed ban is rolled
back out of the local ban list so it can not wedge later bans by being
re-rendered into every subsequent update. A failed unban is not rolled back;
the range is already gone locally and the next successful update converges
the rule.

This backend manages only the rule's source ranges. The security policy, the
deny rule at the given priority, and the policy's attachment to a backend
service or load balancer must already exist.

Requires C<gcloud> in the C<PATH>, authenticated (eg via an activated service
account) with rights to update the policy.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.

The options hash accepts the following.

    - gcloud_cmd :: Path to the gcloud binary.
        - Default :: gcloud

    - policy :: Name of the security policy. Required.
        - Default :: undef

    - priority :: Priority of the deny rule whose source ranges are managed.
        - Default :: 1000

    - project :: Optional GCP project; appended as --project when set.
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
				30 => 'policyNotDefined',
				31 => 'banCidrFailed',
				32 => 'unbanCidrFailed',
				33 => 'cidrItemNotCidr',
				34 => 'cidrNotSupported',
				35 => 'listCidrFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		options      => {},
		ports        => [],
		protocols    => [],
		testing      => undef,
		test_data    => undef,
		prefix       => 'kur',
		name         => undef,
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
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

	if ( !defined( $self->{options}{policy} ) || $self->{options}{policy} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option policy is undef or blank';
		$self->warn;
	}

	$self->{options}{gcloud_cmd} = 'gcloud' if ( !defined( $self->{options}{gcloud_cmd} ) );
	$self->{options}{priority}   = 1000     if ( !defined( $self->{options}{priority} ) );

	return $self;
} ## end sub new

# Internal helper. Returns the --project argument to append to every gcloud
# invocation, or nothing when no project is configured.
#
# Emitting the flag only when the option is set is deliberate rather than
# defaulting to one here. With it left off, gcloud uses whichever project is
# set in the active configuration, which is what an instance running in an
# already configured environment wants. It only needs specifying on a host
# whose account can see several projects and whose default is not the right
# one.
#
# Takes no arguments.
#
# Returns the argument as a string with a leading space, ready to be
# concatenated onto a command, or the empty string when the project option is
# unset or empty. Never returns undef.
#
#     # with the project option set
#     $self->_suffix;    # ' --project my-project'
#
#     # with no project configured
#     $self->_suffix;    # ''
sub _suffix {
	my ($self) = @_;

	if ( defined( $self->{options}{project} ) && $self->{options}{project} ne '' ) {
		return ' --project ' . $self->{options}{project};
	}
	return '';
} ## end sub _suffix

# Internal helper. Renders the current bans into the source range list that
# the Cloud Armor rule update takes.
#
# A Cloud Armor rule's source ranges are replace-in-full: there is no add or
# remove one range call, so every ban and unban rewrites the whole list from
# the internal state. That is what this produces.
#
# Everything is emitted as CIDR, so a single address gets an explicit host
# prefix appended, /32 or /128 by family. Banned ranges already carry a prefix
# and go out as they are. Both families go into the same rule.
#
# Note the separator is a comma rather than a space, unlike the AWS and Azure
# backends. That is what --src-ip-ranges expects, and it means the whole list
# is one shell word, so no quoting is needed around it.
#
# Single addresses and ranges are pulled from two separate internal lists and
# emitted as two sorted runs rather than one merged sorted list, so the
# addresses come first and the ranges after. That is stable, which is what
# matters for the test_data comparisons, just not globally sorted.
#
# Takes no arguments; the bans come from the object's banned and banned_cidr
# hashes.
#
# Returns the ranges as a single comma joined string, ready to follow
# --src-ip-ranges on the command line. Returns the empty string when nothing
# is banned.
#
#     # with 10.0.0.1, 2001:db8::1, and 10.0.0.0/8 banned
#     $self->_ranges;
#     #   '10.0.0.1/32,2001:db8::1/128,10.0.0.0/8'
#
#     # with nothing banned
#     $self->_ranges;    # ''
sub _ranges {
	my ($self) = @_;

	my @ranges;
	foreach my $ip ( sort( keys( %{ $self->{banned} } ) ) ) {
		push( @ranges, $ip . ( ( $ip =~ /\A$IPv4_re\z/ ) ? '/32' : '/128' ) );
	}

	# CIDR ranges already carry a prefix, so they are emitted verbatim
	foreach my $cidr ( sort( keys( %{ $self->{banned_cidr} } ) ) ) {
		push( @ranges, $cidr );
	}

	return join( ',', @ranges );
} ## end sub _ranges

# Internal helper. Returns the gcloud command that writes the current bans
# into the Cloud Armor rule's source ranges. This is the command every ban,
# unban, re_init, teardown, and flush ultimately runs.
#
# The rule is addressed by its priority within the policy rather than by a
# name, since that is how Cloud Armor identifies rules. It is rewritten in
# full each time, as gcloud offers no incremental range add or remove, and
# there is no concurrency guard: two processes updating the same rule at once
# will each write back a list based on their own state and the last one wins.
#
# Takes no arguments; the policy, priority, ranges, and project are all
# assembled from the object.
#
# Returns the command as a single string ready to hand to the runner. The
# gcloud binary comes from the gcloud_cmd option, 'gcloud' by default.
#
#     # policy my-policy at priority 1000, with 10.0.0.1 and 10.0.0.0/8 banned
#     $self->_update_command;
#     #   gcloud compute security-policies rules update 1000 --security-policy my-policy --src-ip-ranges 10.0.0.1/32,10.0.0.0/8
sub _update_command {
	my ($self) = @_;

	return
		  $self->{options}{gcloud_cmd}
		. ' compute security-policies rules update '
		. $self->{options}{priority}
		. ' --security-policy '
		. $self->{options}{policy}
		. ' --src-ip-ranges '
		. $self->_ranges
		. $self->_suffix;
} ## end sub _update_command

# Internal helper. Returns the gcloud command that confirms the Cloud Armor
# rule exists, used by init and by check.
#
# Since this backend creates nothing, the rule existing at the configured
# priority is the whole of its setup, and a rule deleted out from under a
# running process is the failure this detects. init runs it so a misconfigured
# policy or priority fails immediately rather than at the first ban, and check
# runs it to decide whether the self heal path should re-push the current
# bans.
#
# Only the exit status is looked at; nothing parses the rule definition that
# comes back.
#
# Takes no arguments.
#
# Returns the command as a single string ready to hand to the runner, whose
# exit status is 0 when the rule is there.
#
#     $self->_describe_command;
#     #   gcloud compute security-policies rules describe 1000 --security-policy my-policy
#
#     # with the project option set, it is appended
#     #   gcloud compute security-policies rules describe 1000 --security-policy my-policy --project my-project
sub _describe_command {
	my ($self) = @_;

	return
		  $self->{options}{gcloud_cmd}
		. ' compute security-policies rules describe '
		. $self->{options}{priority}
		. ' --security-policy '
		. $self->{options}{policy}
		. $self->_suffix;
} ## end sub _describe_command

# Internal helper. Runs one gcloud command, turns a non zero exit into an
# error, and optionally undoes a speculative state change first.
#
# The rollback exists because of the order the ban path works in. The address
# is added to the internal ban list before the command runs, since the command
# is built from that list, so a failed push would otherwise leave the object
# believing an address is banned when nothing was written. Handing in a
# closure that removes it again keeps the internal state honest.
#
# It has to run before warn rather than after, because errors in this dist are
# fatal by default: warn may not return, and anything after it would never
# execute.
#
# Only the paths that add something pass a rollback. Unbanning removes from
# the list before the command too, but leaving an address out of the list
# after a failed unban is the safer of the two wrong answers, so those callers
# pass nothing.
#
# stderr is folded into stdout so that whatever gcloud complained about ends
# up in the errorString. The output is only used for that; nothing parses it.
#
# Args:
#
#     command    - The complete shell command to run, as a plain string,
#                  normally from _update_command or _describe_command. Run
#                  through the shell, so it is expected to be already quoted
#                  as needed.
#
#     error_flag - The numeric error code to raise on a non zero exit, so the
#                  error reads as the operation that triggered it. Callers
#                  pass the code matching themselves: 12 from init, 13 from
#                  ban, 14 from unban, 31 and 32 from the CIDR paths.
#
#     rollback   - Optional coderef, called with no arguments if and only if
#                  the command fails, before the error is raised. Expected to
#                  undo whatever internal state change was made in
#                  anticipation of the command succeeding. Omitted by callers
#                  that have nothing to undo.
#
# Returns nothing, on success and on failure alike.
#
#     # from init, just verifying the rule is there
#     $self->_run( $self->_describe_command, 12 );
#
#     # from ban, undoing the speculative add if the push fails
#     $self->_run( $command, 13, sub { delete( $self->{banned}{ $opts{ban} } ) } );
sub _run {
	my ( $self, $command, $error_flag, $rollback ) = @_;

	my $output = `$command 2>&1`;
	if ( $? != 0 ) {
		# errors are fatal, so any state rollback has to happen before warn
		$rollback->() if ( defined($rollback) );
		$self->{error}       = $error_flag;
		$self->{errorString} = 'command "' . $command . '" failed... ' . $output;
		$self->warn;
	}

	return;
} ## end sub _run

=head2 init

Initiates the backend, verifying the deny rule at the configured priority
exists via C<gcloud compute security-policies rules describe>.

=cut

sub init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{inited} ) {
		$self->{error}       = 18;
		$self->{errorString} = 'backend has already been inited';
		$self->warn;
	}

	my @commands = ( $self->_describe_command );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		$self->_run( $commands[0], 12 );
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then added to the ban list. The rule's source ranges are
then rewritten via C<gcloud compute security-policies rules update>, the IP
included as a /32 (IPv4) or /128 (IPv6) range. Banning an already banned IP
is a noop.

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
		$self->_run( $command, 13, sub { delete( $self->{banned}{ $opts{ban} } ) } );
	}
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then removed from the ban list. The rule's source ranges are
rewritten without it via C<gcloud compute security-policies rules update>.
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
CIDR range and lowercased, then added to the rule's source ranges via
C<gcloud compute security-policies rules update>. Banning an already banned
range is a noop.

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
		$self->_run( $command, 31, sub { delete( $self->{banned_cidr}{ $opts{ban} } ) } );
	}
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased, then the rule's source ranges are rewritten
without it. Unbanning a range that is not banned is a noop.

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

	delete( $self->{banned_cidr}{ $opts{ban} } );

	my $command = $self->_update_command;
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		$self->_run( $command, 32 );
	}
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

Tears down and re-initiates, then re-applies the full retained banned set
(single IPs and CIDR ranges) to the rule's source ranges with a single
gcloud update.

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

Empties the rule's source ranges. The internal ban list is kept so a
following re_init restores them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	# render the update with an empty ban set without disturbing the retained lists
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

Verifies the rule still exists via C<gcloud compute security-policies rules
describe>. Returns a true value on a zero exit and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	my $command = $self->_describe_command;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
		return 1;
	}

	my $output = `$command 2>&1`;
	return $? == 0 ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs and CIDR ranges at once by clearing the
ban lists and rewriting the rule's source ranges empty with a single gcloud
update.

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

	# the single update below rewrites the rule with both sets empty at once
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

=head2 30, policyNotDefined

The option policy is undef or blank.

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

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::cloud_armor
