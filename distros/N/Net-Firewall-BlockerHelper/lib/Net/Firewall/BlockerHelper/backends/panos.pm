package Net::Firewall::BlockerHelper::backends::panos;

use 5.006;
use strict;
use warnings;
use base         qw( Error::Helper Net::Firewall::BlockerHelper::Util );
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);

=head1 NAME

Net::Firewall::BlockerHelper::backends::panos - Palo Alto Networks PAN-OS backend via the User-ID XML API.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Net::Firewall::BlockerHelper;

    my $fw_helper = Net::Firewall::BlockerHelper->new(
        backend => 'panos',
        name    => 'ssh',
        options => {
            host => 'fw.example.org',
            key  => $panos_api_key,
            tag  => 'blocklist',
        },
    );

    $fw_helper->init_backend;
    $fw_helper->ban( ban => '1.2.3.4' );
    $fw_helper->unban( ban => '1.2.3.4' );

=head1 DESCRIPTION

Blocks IPs on a Palo Alto Networks PAN-OS firewall by registering them with a
tag through the User-ID XML API. A Dynamic Address Group (DAG) on the firewall
is configured to match that tag, and a security policy references the DAG.
Banning an IP is then a matter of registering the IP-to-tag mapping; the DAG
membership, and therefore the enforcement, updates without a commit.

This backend manages only the IP registrations. The Dynamic Address Group
matching the tag and the security policy referencing it must already exist on
the firewall.

Auth is via a PAN-OS API key (the C<key> option), which you generate out of
band (the C<type=keygen> API call or the web UI). The same tag holds both
IPv4 and IPv6 registrations.

Blocking is per IP; ports and protocols belong on the referencing policy, so
specifying them here is an error.

L<LWP::UserAgent> is loaded at run time, so it is only required when this
backend is actually used. For https, L<LWP::Protocol::https> must be present
as well.

=head1 METHODS

=head2 new

Initiates the object.

    - options :: Backend specific options. See below.
    - prefix :: Prefix to use. Must match /^[a-zA-Z0-9]+$/. Default kur.
    - name :: Name of this instance. Required.

Ports and protocols are not supported and specifying either is an error.

The options hash accepts the following.

    - host :: PAN-OS host, optionally host:port. Required.
        - Default :: undef

    - key :: PAN-OS API key. Required.
        - Default :: undef

    - tag :: The tag registered IPs are given, matched by the Dynamic Address
            Group.
        - Default :: <prefix>_<name>

    - vsys :: Optional vsys the registrations are scoped to (eg vsys1).
        - Default :: undef

    - scheme :: 'https' or 'http'.
        - Default :: https

    - insecure :: If true, skip TLS certificate verification.
        - Default :: 0

    - timeout :: HTTP timeout in seconds.
        - Default :: 30

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
				30 => 'hostNotDefined',
				31 => 'keyNotDefined',
				32 => 'banCidrFailed',
				33 => 'unbanCidrFailed',
				34 => 'cidrItemNotCidr',
				35 => 'cidrNotSupported',
				36 => 'listCidrFailed',
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
		inited         => 0,
		banned         => {},
		banned_cidr    => {},
		cidr_supported => 1,
		ua             => undef,
	};
	bless $self;

	# blocking is per IP; ports/protocols belong on the referencing policy
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 26;
		$self->{errorString} = 'the panos backend registers whole IPs and does not support ports';
		$self->warn;
	}
	if ( defined( $opts{protocols} ) && ref( $opts{protocols} ) eq 'ARRAY' && defined( $opts{protocols}[0] ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 27;
		$self->{errorString} = 'the panos backend registers whole IPs and does not support protocols';
		$self->warn;
	}

	# make sure prefix is sane if defined
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

	if ( !defined( $self->{options}{host} ) || $self->{options}{host} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 30;
		$self->{errorString} = 'the option host is undef or blank';
		$self->warn;
	}
	if ( !defined( $self->{options}{key} ) || $self->{options}{key} eq '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 31;
		$self->{errorString} = 'the option key is undef or blank';
		$self->warn;
	}

	# defaults
	$self->{options}{scheme}   = 'https' if ( !defined( $self->{options}{scheme} ) );
	$self->{options}{insecure} = 0       if ( !defined( $self->{options}{insecure} ) );
	$self->{options}{timeout}  = 30      if ( !defined( $self->{options}{timeout} ) );
	if ( defined( $self->{name} ) && !defined( $self->{options}{tag} ) ) {
		$self->{options}{tag} = $self->{prefix} . '_' . $self->{name};
	}

	return $self;
} ## end sub new

# Internal helper. Returns the URL of the PAN-OS XML API.
#
# There is a single endpoint. What happens is decided by the type and cmd form
# parameters in the posted body rather than by the path, so unlike the REST
# backends there is no URL to build per operation.
#
# Takes no arguments; the scheme and host come from the options.
#
# Returns the URL as a string, with its trailing slash, which PAN-OS expects.
#
#     $self->_url;    # https://pan.example.org/api/
sub _url {
	my ($self) = @_;

	return $self->{options}{scheme} . '://' . $self->{options}{host} . '/api/';
}

# Internal helper. Assembles a form encoded request body from named
# parameters, used to build every request this backend sends.
#
# The keys are emitted in a fixed order rather than in hash order, so the same
# parameters always produce the same bytes. Without that the body recorded in
# test_data would vary run to run and could not be compared against a fixed
# expected string.
#
# Parameters that are undef are skipped rather than emitted empty, which is
# how the optional vsys is left out on an appliance that does not use virtual
# systems. Note that only the five known keys are ever emitted; anything else
# passed in is silently ignored, since the ordering list is what drives the
# output.
#
# Every value is percent encoded, which matters for cmd in particular since it
# carries XML.
#
# Args:
#
#     %params - The parameters to encode. Recognized keys, emitted in this
#               order, are: type, the API call type such as 'op' or 'user-id';
#               action; key, the API key; cmd, the XML command; and vsys, the
#               virtual system. Any may be omitted or undef, in which case it
#               is left out.
#
# Returns the body as a form urlencoded string, ready to POST to _url.
#
#     $self->_form_body( type => 'op', key => 'secret', cmd => '<show/>' );
#     #   type=op&key=secret&cmd=%3Cshow%2F%3E
sub _form_body {
	my ( $self, %params ) = @_;

	my @pairs;
	foreach my $key (qw(type action key cmd vsys)) {
		next if ( !defined( $params{$key} ) );
		push( @pairs, $key . '=' . $self->_uri_escape( $params{$key} ) );
	}

	return join( '&', @pairs );
} ## end sub _form_body

# Internal helper. Builds the User-ID uid-message XML that tags or untags one
# address.
#
# This backend does not write firewall rules or manage an address group.
# PAN-OS Dynamic Address Groups are defined by a tag match, so blocking works
# by attaching the configured tag to an address through the User-ID API; the
# DAG then picks it up and whatever policy references that group applies. That
# indirection is why a ban here touches no rule and no group directly.
#
# The XML is assembled by string concatenation rather than through an XML
# writer, so nothing escapes the values. That is safe for the addresses and
# configured tag names that actually reach it, but a tag holding an angle
# bracket or a quote would produce malformed XML.
#
# Args:
#
#     action - What to do, as a plain string: 'register' to attach the tag or
#              'unregister' to remove it. Used as the element name, so
#              anything else would produce XML PAN-OS rejects.
#
#     ip     - The address to tag, as a plain string. Expected to be an
#              already validated and lowercased IPv4 or IPv6 address. Both
#              families go through the same path; PAN-OS does not split tags
#              by family.
#
# Returns the uid-message as an XML string, ready to become the cmd parameter
# of a user-id request.
#
#     $self->_uid_message( 'register', '10.0.0.1' );
#     #   <uid-message><version>2.0</version><type>update</type><payload><register><entry ip="10.0.0.1"><tag><member>blocklist</member></tag></entry></register></payload></uid-message>
#
#     $self->_uid_message( 'unregister', '10.0.0.1' );
#     #   the same with <unregister> in place of <register>
sub _uid_message {
	my ( $self, $action, $ip ) = @_;

	return
		  '<uid-message><version>2.0</version><type>update</type><payload><'
		. $action
		. '><entry ip="'
		. $ip
		. '"><tag><member>'
		. $self->{options}{tag}
		. '</member></tag></entry></'
		. $action
		. '></payload></uid-message>';
} ## end sub _uid_message

# Internal helper. Builds the complete request body that tags or untags one
# address, which is what every ban and unban posts.
#
# This is just the uid-message wrapped up as a user-id API call with the key
# attached. The vsys parameter is only included when the option is set, since
# an appliance without virtual systems does not want it.
#
# Note the API key is part of the body here, so unlike the vyos backend there
# is no separation between a secret free operation and a credentialed one; the
# testing paths in this backend record what they record with that in mind.
#
# Args:
#
#     action - What to do, as a plain string, 'register' or 'unregister'.
#              Passed straight to _uid_message.
#
#     ip     - The address to tag, as a plain string. Expected to be an
#              already validated and lowercased IPv4 or IPv6 address.
#
# Returns the body as a form urlencoded string, ready to POST to _url.
#
#     $self->_register_body( 'register', '10.0.0.1' );
#     #   type=user-id&key=secret&cmd=%3Cuid-message%3E...%3C%2Fuid-message%3E
sub _register_body {
	my ( $self, $action, $ip ) = @_;

	return $self->_form_body(
		type => 'user-id',
		key  => $self->{options}{key},
		cmd  => $self->_uid_message( $action, $ip ),
		( defined( $self->{options}{vsys} ) ? ( vsys => $self->{options}{vsys} ) : () ),
	);
} ## end sub _register_body

# Internal helper. Builds the request body for a harmless read only call, used
# by init and check to confirm the appliance is reachable and the key works.
#
# Since this backend creates nothing on the appliance, there is no setup whose
# presence could be verified. What can be checked is that the API answers and
# the key is still valid, so a show system info is issued purely for its
# status: nothing parses what comes back.
#
# It is deliberately the cheapest call that still exercises authentication.
# The vsys parameter is included when set, so the probe goes through the same
# virtual system the real calls will.
#
# Takes no arguments; the key and vsys come from the options.
#
# Returns the body as a form urlencoded string, ready to POST to _url.
#
#     $self->_probe_body;
#     #   type=op&key=secret&cmd=%3Cshow%3E%3Csystem%3E%3Cinfo%3E%3C%2Finfo%3E%3C%2Fsystem%3E%3C%2Fshow%3E
sub _probe_body {
	my ($self) = @_;

	return $self->_form_body(
		type => 'op',
		key  => $self->{options}{key},
		cmd  => '<show><system><info></info></system></show>',
		( defined( $self->{options}{vsys} ) ? ( vsys => $self->{options}{vsys} ) : () ),
	);
} ## end sub _probe_body

# Internal helper. Performs one HTTP request against the PAN-OS XML API. Every
# call this backend makes to the appliance goes through here.
#
# There is one subtlety that makes this different from the JSON backends:
# PAN-OS reports application level failures with an HTTP 200. A rejected key
# or a malformed command comes back as a perfectly successful HTTP response
# whose XML carries status="error", so checking the HTTP status alone would
# treat those as successes and a ban would silently do nothing. The response
# body is therefore also checked for a top level status="success", and
# anything else is a failure regardless of the HTTP code.
#
# The user agent is built on first use and cached on the object. LWP::UserAgent
# is loaded with require at that point rather than at compile time, since only
# the HTTP backends need it; failing to load it dies with an explanation
# naming this backend. The insecure option turns off certificate verification,
# which is there because a PAN-OS appliance commonly presents a self signed
# certificate.
#
# There is no method or URL argument, since every call is a POST to the one
# endpoint. Authentication is the key inside the body rather than a header.
#
# Any failure, HTTP level or XML level, dies rather than setting an error. The
# callers wrap this in eval and turn the exception into the appropriate error
# code.
#
# Never called in testing mode; those paths record the bodies instead.
#
# Args:
#
#     body - The complete form urlencoded body to post, as a plain string,
#            normally from _register_body or _probe_body. Carries the API key.
#
# Returns the raw XML response body as a string. Note it is not parsed beyond
# the status check; callers that care inspect it themselves.
#
#     $self->_request( $self->_register_body( 'register', $ip ) );
#
#     # the usual shape at the call sites
#     eval { $self->_request( $self->_probe_body ); };
#     if ($@) { ... raise backendInitError ... }
sub _request {
	my ( $self, $body ) = @_;

	if ( !defined( $self->{ua} ) ) {
		local $@;
		eval {
			require LWP::UserAgent;
			my %args = (
				agent   => 'Net::Firewall::BlockerHelper/' . $VERSION,
				timeout => $self->{options}{timeout},
			);
			if ( $self->{options}{insecure} ) {
				$args{ssl_opts} = { verify_hostname => 0, SSL_verify_mode => 0 };
			}
			$self->{ua} = LWP::UserAgent->new(%args);
			1;
		} or die( 'failed to load LWP::UserAgent, which the panos backend requires... ' . $@ );
	}

	my @headers = ( 'Content-Type' => 'application/x-www-form-urlencoded' );

	require HTTP::Request;
	my $request = HTTP::Request->new( 'POST', $self->_url, \@headers, $body );

	my $response = $self->{ua}->request($request);
	my $content  = $response->decoded_content;

	if ( !$response->is_success || !defined($content) || $content !~ /status="success"/ ) {
		die(      'PAN-OS API call failed... HTTP status... '
				. $response->status_line
				. ' body... '
				. ( defined($content) ? $content : '' ) );
	}

	return $content;
} ## end sub _request

=head2 init

Initiates the backend. Verifies the key and connectivity with an op command.

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
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $self->_probe_body } ];
	} else {
		local $@;
		eval { $self->_request( $self->_probe_body ); 1; } or do {
			$self->{error}       = 23;
			$self->{errorString} = 'init failed. probing the API failed... ' . $@;
			$self->warn;
		};
	}

	$self->{inited} = 1;
} ## end sub init

=head2 ban

Bans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then registered with the tag by POSTing a User-ID
C<register> uid-message to the XML API. Banning an already banned IP is a
noop.

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

	my $body = $self->_register_body( 'register', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request($body); 1; } or do {
			$self->{error}       = 13;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned}{ $opts{ban} } = 1;
} ## end sub ban

=head2 unban

Unbans an IP. The value of ban is validated as being a IPv4 or IPv6 address
and lowercased, then unregistered from the tag by POSTing a User-ID
C<unregister> uid-message to the XML API. Unbanning an IP that is not
banned is a noop.

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

	my $body = $self->_register_body( 'unregister', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request($body); 1; } or do {
			$self->{error}       = 14;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned}{ $opts{ban} } );
} ## end sub unban

=head2 ban_cidr

Bans a CIDR range by registering it with the tag via a User-ID C<register>
uid-message. PAN-OS User-ID accepts a network prefix in the same manner as
a single address. The value of ban is validated as being a IPv4 or IPv6
CIDR range and lowercased. Banning an already banned range is a noop.

    $backend->ban_cidr(ban => '1.2.3.0/24');

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
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
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

	my $body = $self->_register_body( 'register', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request($body); 1; } or do {
			$self->{error}       = 32;
			$self->{errorString} = 'banning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	$self->{banned_cidr}{ $opts{ban} } = 1;
} ## end sub ban_cidr

=head2 unban_cidr

Unbans a CIDR range by unregistering it from the tag via a User-ID
C<unregister> uid-message. The value of ban is validated as being a IPv4 or
IPv6 CIDR range and lowercased. Unbanning a range that is not banned is a
noop.

    $backend->unban_cidr(ban => '1.2.3.0/24');

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
		$self->{error}       = 34;
		$self->{errorString} = 'Bad ref type for ban... ref is "' . ref( $opts{ban} ) . '"';
		$self->warn;
		return;
	} elsif ( !$self->_valid_cidr( $opts{ban} ) ) {
		$self->{error}       = 34;
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

	my $body = $self->_register_body( 'unregister', $opts{ban} );

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $body } ];
	} else {
		local $@;
		eval { $self->_request($body); 1; } or do {
			$self->{error}       = 33;
			$self->{errorString} = 'unbanning "' . $opts{ban} . '" failed... ' . $@;
			$self->warn;
			return;
		};
	}

	delete( $self->{banned_cidr}{ $opts{ban} } );
} ## end sub unban_cidr

=head2 list_cidr

List banned CIDR ranges. Returns an array of the currently banned CIDR
ranges. Single IPs are not included; for those see L</list>.

    my @banned_cidrs = $backend->list_cidr;

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

Tears down and re-inits, then re-registers all previously added bans.
Registrations are runtime state on the firewall, so this is how they are
restored after a reboot or a User-ID cache flush.

=cut

sub re_init {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	# teardown is best effort here as a partially or fully wiped setup is
	# exactly what re_init needs to recover from
	{
		local $@;
		eval { $self->teardown; };
	}
	$self->init;

	# both single IPs and CIDR ranges are re-registered the same way
	my @to_ban = ( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) );

	my @re_init_test_data;
	foreach my $item (@to_ban) {
		my $body = $self->_register_body( 'register', $item );

		if ( $self->{testing} ) {
			push( @re_init_test_data, { method => 'POST', url => $self->_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request($body); 1; } or do {
				$self->{error}       = 13;
				$self->{errorString} = 'banning "' . $item . '" failed... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( keys( %{ ...}))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@re_init_test_data;
	}

	$self->{inited} = 1;
} ## end sub re_init

=head2 teardown

Tears down the setup by unregistering each currently banned IP. The internal
list of bans is kept, so a following re_init will re-add them.

=cut

sub teardown {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	$self->{inited} = 0;

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) ) ) {
		my $body = $self->_register_body( 'unregister', $item );
		if ( $self->{testing} ) {
			push( @requests, { method => 'POST', url => $self->_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request($body); 1; } or do {
				$self->{error}       = 17;
				$self->{errorString} = 'teardown failed unregistering "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
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

Verifies the key and connectivity are still usable with an op command.
Returns a true value if so and a false value otherwise.

=cut

sub check {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = [ { method => 'POST', url => $self->_url, content => $self->_probe_body } ];
		return 1;
	}

	local $@;
	eval { $self->_request( $self->_probe_body ); 1; } or return 0;

	return 1;
} ## end sub check

=head2 flush

Removes all currently banned IPs at once by unregistering them and forgetting
them.

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

	my @requests;
	foreach my $item ( sort( keys( %{ $self->{banned} } ), keys( %{ $self->{banned_cidr} } ) ) ) {
		my $body = $self->_register_body( 'unregister', $item );
		if ( $self->{testing} ) {
			push( @requests, { method => 'POST', url => $self->_url, content => $body } );
		} else {
			local $@;
			eval { $self->_request($body); 1; } or do {
				$self->{error}       = 25;
				$self->{errorString} = 'flush failed unregistering "' . $item . '"... ' . $@;
				$self->warn;
			};
		}
	} ## end foreach my $item ( sort( keys( %{ $self->{banned...})))

	if ( $self->{testing} ) {
		$self->{frontend_obj}->{test_data} = \@requests;
	}

	$self->{banned}      = {};
	$self->{banned_cidr} = {};
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

=head2 23, initFailed

init failed. Probing the API with an op command failed.

=head2 24, checkFailed

The backend check raised an error.

=head2 25, flushFailed

Failed to flush the bans.

=head2 26, portsNotSupported

Ports were specified, but the backend does not support ports.

=head2 27, protocolsNotSupported

Protocols were specified, but the backend does not support protocols.

=head2 30, hostNotDefined

The option host is undef or blank.

=head2 31, keyNotDefined

The option key is undef or blank.

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

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.ent> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Net::Firewall::BlockerHelper::backends::panos
