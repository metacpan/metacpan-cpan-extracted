package Net::Firewall::BlockerHelper::backends::dns_rpz;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::dns_rpz - DNS RPZ blocklist backend via nsupdate.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'dns_rpz',
        name    => 'resolver',
        options => {
            zone    => 'rpz.example.org',
            keyfile => '/etc/rpz.key',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs at the DNS layer using a BIND Response Policy Zone (RPZ). By
default the C<rpz-client-ip> trigger is used, so a banned IP is prevented from
resolving anything through the resolver (the policy action is NXDOMAIN via a
C<CNAME .> record). Set the C<trigger> option to C<ip> to instead use the
C<rpz-ip> trigger, which rewrites answers that contain the banned IP.

Records are added and removed with L<nsupdate(1)> (the DNS update protocol,
TSIG authenticated), so this backend runs the nsupdate command rather than
speaking HTTP. The RPZ zone must already exist and be referenced from the
resolver's C<response-policy> configuration.

The owner name is the RPZ IP format: for IPv4 C<1.2.3.4> it is
C<< 32.4.3.2.1.rpz-client-ip.<zone> >>, and for IPv6 the eight groups are
reversed with the longest zero run replaced by C<zz>, prefixed with the
C<128> length.

Blocking is per IP; ports and protocols are not supported and specifying
either is an error.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
    - name :: Required by Net::Firewall::BlockerHelper, otherwise unused.

The options hash accepts the following. zone and keyfile are required.

    - zone :: The RPZ zone name.
        - Default :: undef

    - keyfile :: Full path to the TSIG key file authenticating to the server.
        - Default :: undef

    - trigger :: 'client-ip' (block the querying client) or 'ip' (rewrite
            answers containing the IP).
        - Default :: client-ip

    - server :: Optional server to send the updates to; adds a server line.
        - Default :: undef

    - ttl :: TTL in seconds for the created records.
        - Default :: 60

    - nsupdate :: The nsupdate command to use.
        - Default :: nsupdate

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
				20 => 'triggerInvalid',
				23 => 'initFailed',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'portsNotSupported',
				27 => 'protocolsNotSupported',
				30 => 'zoneInvalid',
				31 => 'keyfileInvalid',
				32 => 'banCidrFailed',
				33 => 'unbanCidrFailed',
				34 => 'cidrItemNotCidr',
				35 => 'cidrNotSupported',
				36 => 'listCidrFailed',
				37 => 'serverInvalid',
				38 => 'ttlInvalid',
				39 => 'nsupdateInvalid',
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
		cidr_supported => 0,
	};
	bless $self;

	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the dns_rpz backend blocks whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the dns_rpz backend blocks whole IPs and does not support protocols';
		$self->warn;
	}

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

	if ( !defined( $self->{options}{zone} ) || $self->{options}{zone} !~ /^[a-zA-Z0-9.\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 30;
		$self->{errorString}
			= 'the option zone is '
			. ( defined( $self->{options}{zone} ) ? '"' . $self->{options}{zone} . '" and not a valid zone' : 'undef' );
		$self->warn;
	}

	# keyfile must be free of whitespace and single quotes so it is safe to embed
	if ( !defined( $self->{options}{keyfile} ) || $self->{options}{keyfile} !~ /^[^'\s]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 31;
		$self->{errorString}
			= 'the option keyfile is '
			. (
			defined( $self->{options}{keyfile} )
			? '"' . $self->{options}{keyfile} . '" which contains whitespace or single quotes'
			: 'undef'
			);
		$self->warn;
	} ## end if ( !defined( $self->{options}{keyfile} )...)

	$self->{options}{trigger} = 'client-ip' if ( !defined( $self->{options}{trigger} ) );

	# the following are embedded in the shell command _nsupdate_command builds,
	# so limit each to characters safe inside its single quoted printf string

	# '' is treated the same as undef when the command is built
	if (   defined( $self->{options}{server} )
		&& $self->{options}{server} ne ''
		&& $self->{options}{server} !~ /^[a-zA-Z0-9.:\-]+$/ )
	{
		$self->{perror} = 1;
		$self->{error}  = 37;
		$self->{errorString}
			= 'the option server, "' . $self->{options}{server} . '", does not match /^[a-zA-Z0-9.:\-]+$/';
		$self->warn;
	}

	if ( !defined( $self->{options}{ttl} ) ) {
		$self->{options}{ttl} = 60;
	} elsif ( $self->{options}{ttl} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 38;
		$self->{errorString} = 'the option ttl, "' . $self->{options}{ttl} . '", is not an int';
		$self->warn;
	}

	if ( !defined( $self->{options}{nsupdate} ) ) {
		$self->{options}{nsupdate} = 'nsupdate';
	} elsif ( $self->{options}{nsupdate} !~ /^[a-zA-Z0-9.\/_\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 39;
		$self->{errorString}
			= 'the option nsupdate, "' . $self->{options}{nsupdate} . '", does not match /^[a-zA-Z0-9.\/_\-]+$/';
		$self->warn;
	}

	if ( $self->{options}{trigger} ne 'client-ip' && $self->{options}{trigger} ne 'ip' ) {
		$self->{perror}      = 1;
		$self->{error}       = 20;
		$self->{errorString} = 'the option trigger is "' . $self->{options}{trigger} . '" and not "client-ip" or "ip"';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the DNS owner name that the RPZ record for the
# passed IP has to be created under. This is the name the ban and unban
# nsupdate statements operate on, so getting it wrong means writing a record
# that the resolver never consults.
#
# RPZ encodes an address into a domain name by writing a prefix length first
# and then the address backwards, label by label, since DNS names go from most
# specific to least specific while addresses read the other way. A single host
# is a full length prefix, so IPv4 uses 32 and IPv6 uses 128. The result is
# placed under the rpz-<trigger> label inside the policy zone.
#
# For IPv6 the address is first expanded to all eight groups, then reversed,
# then the longest run of zero groups is collapsed to the literal "zz". That
# "zz" is the RPZ spelling of the "::" shorthand. Only the longest run may be
# collapsed, which is why the run is searched for explicitly rather than
# replacing the first run found; collapsing a shorter run would produce a
# different, non canonical name and the record would not be found.
#
# Args:
#
#     ip - The address to encode, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. The family is
#          decided by matching against $IPv4_re, so anything that is not a
#          valid IPv4 address is encoded as IPv6.
#
# Returns the fully qualified owner name as a string, with no trailing dot.
# The trigger and zone come from the options, so the same IP produces a
# different name under a client-ip instance than under an ip instance.
#
#     # trigger 'client-ip', zone 'rpz.example.org'
#     $self->_owner('10.0.0.1');
#     #   32.1.0.0.10.rpz-client-ip.rpz.example.org
#
#     $self->_owner('2001:db8::1');
#     #   128.1.zz.db8.2001.rpz-client-ip.rpz.example.org
#
#     # trigger 'ip', so answers containing the IP are rewritten instead
#     $self->_owner('10.0.0.1');
#     #   32.1.0.0.10.rpz-ip.rpz.example.org
sub _owner {
	my ( $self, $ip ) = @_;

	my $rpz_ip;
	if ( $ip =~ /\A$IPv4_re\z/ ) {
		$rpz_ip = '32.' . join( '.', reverse( split( /\./, $ip ) ) );
	} else {
		# expand the eight IPv6 groups, reverse them, and replace the longest
		# run of zero groups with zz (the RPZ IPv6 encoding)
		my @groups = $self->_v6_groups($ip);
		my @rev    = reverse(@groups);

		# find the longest run of '0' groups
		my ( $best_start, $best_len ) = ( -1, 0 );
		my $i = 0;
		while ( $i < scalar(@rev) ) {
			if ( $rev[$i] eq '0' ) {
				my $j = $i;
				$j++ while ( $j < scalar(@rev) && $rev[$j] eq '0' );
				if ( ( $j - $i ) > $best_len ) {
					$best_len   = $j - $i;
					$best_start = $i;
				}
				$i = $j;
			} else {
				$i++;
			}
		} ## end while ( $i < scalar(@rev) )

		my @out;
		$i = 0;
		while ( $i < scalar(@rev) ) {
			if ( $i == $best_start && $best_len > 0 ) {
				push( @out, 'zz' );
				$i += $best_len;
			} else {
				push( @out, $rev[$i] );
				$i++;
			}
		}

		$rpz_ip = '128.' . join( '.', @out );
	} ## end else [ if ( $ip =~ /\A$IPv4_re\z/)]

	return $rpz_ip . '.rpz-' . $self->{options}{trigger} . '.' . $self->{options}{zone};
} ## end sub _owner

# Internal helper. Expands a possibly abbreviated IPv6 address into its eight
# groups, normalized so that two spellings of the same address always come out
# identical.
#
# This exists because _owner has to reverse the groups and find the longest
# run of zeros, and neither is possible while the address still holds a "::"
# standing in for an unknown number of groups. Normalizing here also means
# "2001:0db8::0001" and "2001:db8::1" produce the same owner name, so a ban
# and a later unban of the same host cannot end up touching two different
# records.
#
# The "::" is expanded by splitting on it and filling the gap with as many
# zero groups as are needed to reach eight. Each group is then lowercased and
# has its leading zeros stripped, with an all zero group left as a single "0"
# rather than an empty string.
#
# Args:
#
#     ip - The IPv6 address to expand, as a plain string. May be in any of the
#          usual spellings: fully written out, abbreviated with "::" anywhere
#          in it including at either end, and in any case. Expected to be a
#          valid address; nothing here checks that, and an IPv4 address or a
#          malformed string will simply produce a nonsense group list rather
#          than an error.
#
# Returns the eight groups as a list of strings, in address order, each a
# lowercase hex string with no leading zeros. Note the groups are returned in
# the order they appear in the address, not reversed; reversing is the
# caller's job.
#
#     $self->_v6_groups('2001:db8::1');
#     #   ( '2001', 'db8', '0', '0', '0', '0', '0', '1' )
#
#     $self->_v6_groups('2001:0DB8:0000:0000:0000:0000:0000:0001');
#     #   ( '2001', 'db8', '0', '0', '0', '0', '0', '1' )   -- same as above
#
#     $self->_v6_groups('::1');
#     #   ( '0', '0', '0', '0', '0', '0', '0', '1' )
#
#     $self->_v6_groups('fe80::');
#     #   ( 'fe80', '0', '0', '0', '0', '0', '0', '0' )
sub _v6_groups {
	my ( $self, $ip ) = @_;

	my @groups;
	if ( $ip =~ /::/ ) {
		my ( $left, $right ) = split( /::/, $ip, 2 );
		my @l = ( defined($left)  && $left ne '' )  ? split( /:/, $left )  : ();
		my @r = ( defined($right) && $right ne '' ) ? split( /:/, $right ) : ();
		my $fill = 8 - scalar(@l) - scalar(@r);
		@groups = ( @l, ('0') x $fill, @r );
	} else {
		@groups = split( /:/, $ip );
	}

	# normalize each group: lowercase, strip leading zeros, empty becomes 0
	foreach my $g (@groups) {
		$g = lc($g);
		$g =~ s/^0+(?=.)//;
		$g = '0' if ( $g eq '' );
	}

	return @groups;
} ## end sub _v6_groups

# Internal helper. Wraps one or more update statements into the complete shell
# command that feeds them to nsupdate. Every change this backend makes to the
# policy zone goes out through here.
#
# nsupdate reads its statements from stdin rather than from arguments, so the
# statements are printed into a pipe. They are assembled in the order nsupdate
# needs: an optional server line, then the zone, then the caller's updates,
# then send. The server line is only emitted when the server option is set to
# something non empty, since leaving it out is what makes nsupdate fall back
# to the SOA MNAME for the zone. The trailing send is what actually transmits
# the update; without it nsupdate would exit having done nothing.
#
# Note the statements are joined with a literal backslash-n inside a single
# quoted printf format, so it is printf that turns them into real newlines,
# not perl.
#
# Args:
#
#     @updates - One or more nsupdate statement lines, as plain strings with
#                no trailing newline, such as
#                'update add 32.1.0.0.10.rpz-client-ip.rpz.example.org 3600 IN CNAME .'
#                They are emitted in the order given, between the zone line
#                and the send. Passing none is not an error and produces a
#                command that connects and sends an empty update.
#
# Returns the command as a single string ready to hand to the runner, of the
# shape "printf '<statements>\n' | <nsupdate> -k '<keyfile>'". The nsupdate
# binary and the keyfile come from the options, and the keyfile is single
# quoted so a path holding spaces survives.
#
#     $self->_nsupdate_command(
#         'update add 32.1.0.0.10.rpz-client-ip.rpz.example.org 3600 IN CNAME .' );
#
#     # with no server option set:
#     #   printf 'zone rpz.example.org\nupdate add 32.1.0.0.10.rpz-client-ip.rpz.example.org 3600 IN CNAME .\nsend\n' | nsupdate -k '/etc/rpz.key'
#
#     # with the server option set to ns1.example.org, a server line leads:
#     #   printf 'server ns1.example.org\nzone rpz.example.org\n...\nsend\n' | nsupdate -k '/etc/rpz.key'
#
#     # several statements go out as one update, so they apply atomically
#     $self->_nsupdate_command( @add_statements );
sub _nsupdate_command {
	my ( $self, @updates ) = @_;

	my @statements;
	if ( defined( $self->{options}{server} ) && $self->{options}{server} ne '' ) {
		push( @statements, 'server ' . $self->{options}{server} );
	}
	push( @statements, 'zone ' . $self->{options}{zone} );
	push( @statements, @updates );
	push( @statements, 'send' );

	return
		  "printf '"
		. join( '\n', @statements )
		. "\\n' | "
		. $self->{options}{nsupdate} . " -k '"
		. $self->{options}{keyfile} . "'";
} ## end sub _nsupdate_command

# Internal helper. Returns the complete shell command that bans the passed IP
# by adding its RPZ record to the policy zone.
#
# The record added is a CNAME pointing at the root, ".", which is how RPZ
# spells the NXDOMAIN action: a resolver consulting the zone answers as though
# the name did not exist. Under the default client-ip trigger that means the
# banned host gets NXDOMAIN for everything it looks up; under the ip trigger
# it means answers containing the banned address are rewritten.
#
# The record is created with the configured ttl, 60 seconds by default. That
# ttl bounds how long a resolver may keep serving the ban after it has been
# lifted, so it is the main reason an unban does not always take effect
# immediately.
#
# Args:
#
#     ip - The address to ban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address. It is turned into an
#          owner name by _owner, so the encoding rules there apply.
#
# Returns the full shell command as a single string, ready for the runner, as
# built by _nsupdate_command.
#
#     $self->_ban_command('10.0.0.1');
#     #   printf 'zone rpz.example.org\nupdate add 32.1.0.0.10.rpz-client-ip.rpz.example.org 60 IN CNAME .\nsend\n' | nsupdate -k '/etc/rpz.key'
sub _ban_command {
	my ( $self, $ip ) = @_;

	return $self->_nsupdate_command(
		'update add ' . $self->_owner($ip) . ' ' . $self->{options}{ttl} . ' IN CNAME .' );
}

# Internal helper. Returns the complete shell command that unbans the passed IP
# by deleting its RPZ record from the policy zone.
#
# This is the exact inverse of _ban_command and deletes the same CNAME record
# it created, matched by owner name, type, and rdata. No ttl appears, as
# nsupdate delete statements do not take one.
#
# Deleting a record that is not there is not an error for nsupdate, so
# unbanning an IP that was never banned succeeds quietly. Note that resolvers
# may keep answering from cache until the record's ttl expires.
#
# Args:
#
#     ip - The address to unban, as a plain string. Expected to be an already
#          validated and lowercased IPv4 or IPv6 address, and to be spelled
#          the same way it was when banned. _owner normalizes IPv6 spellings,
#          so an abbreviated and a fully written out form of the same address
#          both resolve to the same record.
#
# Returns the full shell command as a single string, ready for the runner, as
# built by _nsupdate_command.
#
#     $self->_unban_command('10.0.0.1');
#     #   printf 'zone rpz.example.org\nupdate delete 32.1.0.0.10.rpz-client-ip.rpz.example.org IN CNAME .\nsend\n' | nsupdate -k '/etc/rpz.key'
sub _unban_command {
	my ( $self, $ip ) = @_;

	return $self->_nsupdate_command( 'update delete ' . $self->_owner($ip) . ' IN CNAME .' );
}

=head2 init

Initiates the backend. Nothing is created on the server; the configured
keyfile is just verified to exist and be a file.

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
		$self->{frontend_obj}->{test_data} = 'inited';
	} elsif ( !-f $self->{options}{keyfile} ) {
		$self->{error} = 23;
		$self->{errorString}
			= 'init failed. the keyfile, "' . $self->{options}{keyfile} . '", does not exist or is not a file';
		$self->warn;
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then a C<CNAME .> record is added at the RPZ owner name for
the IP by running nsupdate. Banning an already banned IP is a noop.

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

	my $command = $self->_ban_command( $opts{ban} );
	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
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
and lowercased, then the C<CNAME .> record at the RPZ owner name for the IP
is deleted by running nsupdate. Unbanning an IP that is not banned is a
noop.

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

	my $command = $self->_unban_command( $opts{ban} );
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

=head2 ban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 35;
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

	$self->{error}       = 35;
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

=head2 re_init

Tears down and re-initiates. teardown is called best effort, init is run
again, and then the RPZ record for every retained banned IP is re-added
via nsupdate.

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
	foreach my $item ( keys( %{ $self->{banned} } ) ) {
		my $command = $self->_ban_command($item);
		if ( $self->{testing} ) {
			push( @commands, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 13;
				$self->{errorString}
					= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item ( keys( %{ ...}))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Removes the RPZ record for each currently banned IP. The internal ban list is
kept so a following re_init restores them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @commands;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		my $command = $self->_unban_command($item);
		if ( $self->{testing} ) {
			push( @commands, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 17;
				$self->{errorString}
					= 'teardown failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item ( sort( keys...))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
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

Verifies the keyfile still exists and is a file. Returns a true value if so
and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'check';
		return 1;
	}

	return ( -f $self->{options}{keyfile} ) ? 1 : 0;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by running a nsupdate delete for
each RPZ record and clearing the ban list.

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
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		my $command = $self->_unban_command($item);
		if ( $self->{testing} ) {
			push( @commands, $command );
		} else {
			my $output = `$command 2>&1`;
			if ( $? != 0 ) {
				$self->{error} = 25;
				$self->{errorString}
					= 'flush failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
				$self->warn;
			}
		}
	} ## end foreach my $item ( sort( keys...))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	}

	$self->{banned} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

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

=head2 20, triggerInvalid

The option trigger is not "client-ip" or "ip".

=head2 23, initFailed

Init failed. The keyfile does not exist or is not a file.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

The dns_rpz backend blocks whole IPs and does not support ports.

=head2 27, protocolsNotSupported

The dns_rpz backend blocks whole IPs and does not support protocols.

=head2 30, zoneInvalid

The option zone is undef or not a valid zone name.

=head2 31, keyfileInvalid

The option keyfile is undef or contains whitespace or single quotes.

=head2 32, banCidrFailed

Failed to ban the CIDR range.

=head2 33, unbanCidrFailed

Failed to unban the CIDR range.

=head2 34, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 35, cidrNotSupported

The backend does not support CIDR bans.

=head2 36, listCidrFailed

Failed to get a list of CIDR bans.

=head2 37, serverInvalid

The option server does not match /^[a-zA-Z0-9.:\-]+$/.

=head2 38, ttlInvalid

The option ttl is not an int.

=head2 39, nsupdateInvalid

The option nsupdate does not match /^[a-zA-Z0-9.\/_\-]+$/.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::dns_rpz
