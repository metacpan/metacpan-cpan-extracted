package Net::Firewall::BlockerHelper::backends::nsupdate;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::nsupdate - Dynamic DNS blocklist backend for Net::Firewall::BlockerHelper.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

All this backend does is add and remove TXT records, so two bits of
external setup are required for bans to actually mean anything. First the
zone the records live under must exist on the DNS server and allow dynamic
updates authenticated via the TSIG key, the like of the following in
C<named.conf> for BIND, with the key also declared there via a C<key>
statement matching the keyfile.

    zone "rbl.foo.bar" {
        type primary;
        file "rbl.foo.bar.db";
        allow-update { key "nsupdate-key"; };
    };

Second, a DNS record on its own blocks nothing. Whatever should be turning
away the banned IPs must be configured to consult the resulting blocklist.
Also worth noting is that only TXT records are created, while the usual
DNSBL style lookup checks for an A record, so the consumer needs to be
something that can be pointed at TXT records.

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
            backend => 'nsupdate',
            name => 'ssh',
            options => {
                domain  => 'rbl.foo.bar',
                keyfile => '/etc/nsupdate.key',
            },
        );

    $fw_helper->init_backend;
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->unban(ban => '1.2.3.4');

=head1 DESCRIPTION

Maintains a DNS based blocklist (RBL style) by using L<nsupdate(1)> to
dynamically add and remove TXT records under a BIND zone, equivalent to the
fail2ban nsupdate action. Banning C<1.2.3.4> adds a TXT record at
C<4.3.2.1.E<lt>domainE<gt>>.

nsupdate speaks the DNS update protocol authenticated via a TSIG key, not
HTTP, so this backend runs the nsupdate command rather than using
L<LWP::UserAgent>.

Only IPv4 is supported, matching the fail2ban action; banning an IPv6 IP is
an error. Ports and protocols are not supported and specifying them is an
error. check has nothing it can probe cheaply and always reports healthy.

=head1 METHODS

=head2 new

Initiates the the object.

    - options :: Backend specific options. See below.
        - Default :: {}

    - prefix :: Prefix to use. Must match the regex /^[a-zA-Z0-9]+$/
        - default :: kur

    - name :: Name of this specific instance. This must be specified.
        - default :: undef

Ports and protocols are not supported by this backend and specifying either
is an error.

The options hash accepts the following. domain and keyfile must be
specified.

    - domain :: DNS domain the records are managed under.
        - Default :: undef

    - keyfile :: Full path to the TSIG key file used to authenticate to
            BIND. Verified to exist at init.
        - Default :: undef

    - ttl :: TTL in seconds for the created TXT records.
        - Default :: 60

    - rdata :: Data of the created TXT records.
        - Default :: banned

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
				6  => 'invalidPrefixSpecified',
				7  => 'invalidName',
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
				23 => 'initFailed',
				24 => 'checkFailed',
				25 => 'flushFailed',
				26 => 'portsNotSupported',
				27 => 'protocolsNotSupported',
				28 => 'optionInvalid',
				29 => 'ipv6NotSupported',
				30 => 'banCidrFailed',
				31 => 'unbanCidrFailed',
				32 => 'cidrItemNotCidr',
				33 => 'cidrNotSupported',
				34 => 'listCidrFailed',
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
		frontend_obj => undef,
		inited       => 0,
		banned       => {},
		cidr_supported => 0,
	};
	bless $self;

	# blocking is per IP; DNS records have no concept of ports or protocols
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the nsupdate backend lists whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the nsupdate backend lists whole IPs and does not support protocols';
		$self->warn;
	}

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
	}

	if ( !defined( $self->{options}{domain} ) || $self->{options}{domain} !~ /^[a-zA-Z0-9.\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option domain is '
			. (
			defined( $self->{options}{domain} )
			? '"' . $self->{options}{domain} . '" and not a valid domain'
			: 'undef'
			);
		$self->warn;
	} ## end if ( !defined( $self->{options}{domain} ) ...)

	# no whitespace or single quotes given it is single quoted when passed to the shell
	if ( !defined( $self->{options}{keyfile} ) || $self->{options}{keyfile} !~ /^[^'\s]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option keyfile is '
			. (
			defined( $self->{options}{keyfile} )
			? '"' . $self->{options}{keyfile} . '" which contains whitespace or single quotes'
			: 'undef'
			);
		$self->warn;
	} ## end if ( !defined( $self->{options}{keyfile} )...)

	if ( !defined( $self->{options}{ttl} ) ) {
		$self->{options}{ttl} = 60;
	} elsif ( $self->{options}{ttl} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 28;
		$self->{errorString} = 'the option ttl, "' . $self->{options}{ttl} . '", is not an int';
		$self->warn;
	}

	if ( !defined( $self->{options}{rdata} ) ) {
		$self->{options}{rdata} = 'banned';
	} elsif ( $self->{options}{rdata} !~ /^[a-zA-Z0-9 .,:_\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option rdata, "'
			. $self->{options}{rdata}
			. '", does not match /^[a-zA-Z0-9 .,:_\-]+$/';
		$self->warn;
	}

	if ( !defined( $self->{options}{nsupdate} ) ) {
		$self->{options}{nsupdate} = 'nsupdate';
	} elsif ( $self->{options}{nsupdate} !~ /^[a-zA-Z0-9.\/_\-]+$/ ) {
		$self->{perror} = 1;
		$self->{error}  = 28;
		$self->{errorString}
			= 'the option nsupdate, "'
			. $self->{options}{nsupdate}
			. '", does not match /^[a-zA-Z0-9.\/_\-]+$/';
		$self->warn;
	}

	return $self;
} ## end sub new

# Internal helper. Returns the DNS name that the blocklist record for the
# passed IP lives at, which is the address written backwards under the
# configured domain.
#
# This is the DNSBL naming convention: the octets are reversed so that the
# name reads from most specific to least specific the way DNS names do, then
# placed under the zone. A consumer checking whether an address is listed
# builds the same name and looks it up.
#
# Only IPv4 is handled. This backend rejects IPv6 at ban and unban with
# ipv6NotSupported, matching the fail2ban action it mirrors, so nothing ever
# reaches here with an IPv6 address. Passing one anyway would not error, it
# would just split on dots that are not there and produce a single label,
# giving a nonsense name.
#
# Args:
#
#     ip - The address to encode, as a plain string. Expected to be an already
#          validated IPv4 address such as "10.0.0.1". Nothing here validates
#          it.
#
# Returns the fully qualified record name as a string, with no trailing dot.
#
#     # with the domain option set to rbl.foo.bar
#     $self->_record_name('10.0.0.1');    # 1.0.0.10.rbl.foo.bar
#     $self->_record_name('192.0.2.5');   # 5.2.0.192.rbl.foo.bar
sub _record_name {
	my ( $self, $ip ) = @_;

	my @octets = split( /\./, $ip );

	return join( '.', reverse(@octets) ) . '.' . $self->{options}{domain};
}

# Internal helper. Wraps a list of nsupdate statements into the complete shell
# command that feeds them to nsupdate. Every change this backend makes to the
# zone goes out through here.
#
# nsupdate reads its statements from stdin rather than from arguments, so they
# are printed into a pipe. Note the statements are joined with a literal
# backslash-n inside a single quoted printf format, so it is printf that turns
# them into real newlines, not perl.
#
# Unlike the same named helper in the dns_rpz backend, this one adds nothing
# of its own. There is no server line and no zone line, so nsupdate works out
# the zone from the record name and the server from its SOA, and crucially the
# trailing send is not appended either. Callers pass the complete statement
# list including their own 'send'; leaving it off would build a command that
# connects and then exits without transmitting anything.
#
# Args:
#
#     @statements - The complete list of nsupdate statement lines, as plain
#                   strings with no trailing newline, in the order they should
#                   be fed in, and including the final 'send'. Callers
#                   typically pass either a prereq, an update add, and a send
#                   for a ban, or an update delete and a send for an unban.
#
# Returns the command as a single string ready to hand to the runner, of the
# shape "printf '<statements>\n' | <nsupdate> -k '<keyfile>'". The nsupdate
# binary and the keyfile come from the options, and the keyfile is single
# quoted so a path holding spaces survives.
#
#     # a ban: only add the record if it is not already there
#     $self->_nsupdate_command(
#         'prereq nxrrset 1.0.0.10.rbl.foo.bar TXT',
#         'update add 1.0.0.10.rbl.foo.bar 60 IN TXT "blocked"',
#         'send'
#     );
#     #   printf 'prereq nxrrset 1.0.0.10.rbl.foo.bar TXT\nupdate add 1.0.0.10.rbl.foo.bar 60 IN TXT "blocked"\nsend\n' | nsupdate -k '/etc/nsupdate.key'
#
#     # an unban
#     $self->_nsupdate_command( 'update delete 1.0.0.10.rbl.foo.bar TXT', 'send' );
#     #   printf 'update delete 1.0.0.10.rbl.foo.bar TXT\nsend\n' | nsupdate -k '/etc/nsupdate.key'
sub _nsupdate_command {
	my ( $self, @statements ) = @_;

	return
		  "printf '"
		. join( '\n', @statements )
		. "\\n' | "
		. $self->{options}{nsupdate} . " -k '"
		. $self->{options}{keyfile} . "'";
} ## end sub _nsupdate_command

=head2 init

Initiates the backend. Verifies the keyfile exists.

Note that the zone must allow updates via the key and something must be
consuming the blocklist for bans to have an effect. See L</SYNOPSIS>.

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

Bans an IP. The value of ban is validated as being a IPv4 address; IPv6 is
not supported and is an error. The octets are reversed and a TXT record is
added at that name under the domain, eg banning 1.2.3.4 adds a TXT record
at C<4.3.2.1.E<lt>domainE<gt>>, by piping an update with a nxrrset prereq
into nsupdate authenticated via the TSIG keyfile. Banning an already banned
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
	} elsif ( $opts{ban} =~ /\A$IPv6_re\z/ ) {
		$self->{error}       = 29;
		$self->{errorString} = 'the nsupdate backend only handles IPv4 and "' . $opts{ban} . '" is IPv6';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/ ) {
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 IP';
		$self->warn;
		return;
	}

	if ( $self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'already banned';
		}
		return;
	}

	my $record  = $self->_record_name( $opts{ban} );
	my $command = $self->_nsupdate_command(
		'prereq nxrrset ' . $record . ' TXT',
		'update add ' . $record . ' ' . $self->{options}{ttl} . ' IN TXT "' . $self->{options}{rdata} . '"',
		'send'
	);

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [$command];
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 13;
			$self->{errorString}
				= 'ban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
			return;
		}
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 address; IPv6
is not supported and is an error. The TXT record for the IP is deleted by
piping an update delete for its record name into nsupdate. Unbanning an IP
that is not banned is a noop.

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
	} elsif ( $opts{ban} =~ /\A$IPv6_re\z/ ) {
		$self->{error}       = 29;
		$self->{errorString} = 'the nsupdate backend only handles IPv4 and "' . $opts{ban} . '" is IPv6';
		$self->warn;
		return;
	} elsif ( $opts{ban} !~ /\A$IPv4_re\z/ ) {
		$self->{error}       = 10;
		$self->{errorString} = 'ban item,"' . $opts{ban} . '", does not appear to be a IPv4 IP';
		$self->warn;
		return;
	}

	if ( !$self->{banned}{ $opts{ban} } ) {
		if ( $self->{testing} ) {
			$self->{frontend_obj}->{test_data} = 'not banned';
		}
		return;
	}

	my $record  = $self->_record_name( $opts{ban} );
	my $command = $self->_nsupdate_command( 'update delete ' . $record . ' TXT', 'send' );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = $command;
	} else {
		my $output = `$command 2>&1`;
		if ( $? != 0 ) {
			$self->{error} = 14;
			$self->{errorString}
				= 'unban failed. non-zero exit code for the command... "' . $command . '"... output... ' . $output;
			$self->warn;
			return;
		}
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

CIDR bans are not supported by this backend; this always sets the
cidrNotSupported error.

    $backend->ban_cidr(ban => '1.2.3.0/24');

=cut

sub ban_cidr {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{error}       = 33;
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

	$self->{error}       = 33;
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

=head2 list

List banned IPs. Returns an array of the currently banned IPs from the
internal ban list.

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

Tells the backend to re-init it's self.

This will call teardown, which deletes the record for each banned IP, then
init, and then re-add the TXT record for every retained ban via nsupdate.

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

	my @to_ban = keys( %{ $self->{banned} } );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $record  = $self->_record_name($item);
		my $command = $self->_nsupdate_command(
			'prereq nxrrset ' . $record . ' TXT',
			'update add ' . $record . ' ' . $self->{options}{ttl} . ' IN TXT "' . $self->{options}{rdata} . '"',
			'send'
		);

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

Tears down the setup for the backend by deleting the record for each
currently banned IP. The internal list of bans is kept, so a following
re_init will re-add them.

    $backend->teardown;

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @commands;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		push( @commands, $self->_nsupdate_command( 'update delete ' . $self->_record_name($item) . ' TXT', 'send' ) );
	}

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@commands;
	} else {
		foreach my $item (@commands) {
			my $output = `$item 2>&1`;
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

    $backend->stop;

=cut

sub stop {
	my ( $self, %opts ) = @_;

	return $self->teardown(%opts);
}

=head2 check

There is nothing this backend can cheaply probe, so this always reports
healthy. This is the equivalent of fail2ban's C<actioncheck>.

    my $healthy = $backend->check;

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = 'check';
	}

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by deleting their records and
forgetting them. This is the equivalent of fail2ban's C<actionflush>.

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

	my @commands;
	foreach my $item ( sort( keys( %{ $self->{banned} } ) ) ) {
		push( @commands, $self->_nsupdate_command( 'update delete ' . $self->_record_name($item) . ' TXT', 'send' ) );
	}

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

	$self->{banned} = {};
} ## end sub flush

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>. All
errors are considered fatal.

=head2 1, notInited

The backend has not been inited yet.

=head2 6, invalidPrefixSpecified

The specified prefix did not match /^[a-zA-Z0-9]+$/.

=head2 7, invalidName

The name is either undef or does not match /^[a-zA-Z0-9\-]+$/.

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

=head2 23, initFailed

init failed. The keyfile does not exist or is not a file.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

Ports were specified, but the backend does not support ports.

=head2 27, protocolsNotSupported

Protocols were specified, but the backend does not support protocols.

=head2 28, optionInvalid

One of the specified options failed validation.

=head2 29, ipv6NotSupported

The backend only supports IPv4 and the item is an IPv6 IP.

=head2 30, banCidrFailed

Failed to ban the CIDR range.

=head2 31, unbanCidrFailed

Failed to unban the CIDR range.

=head2 32, cidrItemNotCidr

The item to ban is not a CIDR range. Either wrong ref type or it is not an
IPv4 or IPv6 address followed by a prefix length valid for its family.

=head2 33, cidrNotSupported

The backend does not support CIDR bans.

=head2 34, listCidrFailed

Failed to get a list of CIDR bans.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-firewall-blockerhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Firewall-BlockerHelper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Firewall::BlockerHelper
