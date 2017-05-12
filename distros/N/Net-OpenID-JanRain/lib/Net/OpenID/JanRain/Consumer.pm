my $successResponseClass = "Net::OpenID::JanRain::Consumer::SuccessResponse";
my $failureResponseClass = "Net::OpenID::JanRain::Consumer::FailureResponse";
my $cancelResponseClass = "Net::OpenID::JanRain::Consumer::CancelResponse";
my $setupNeededResponseClass = "Net::OpenID::JanRain::Consumer::SetupNeededResponse";

package Net::OpenID::JanRain::Consumer;

=head1 OVERVIEW

The OpenID identity verification process most commonly uses the
following steps, as visible to the user of this library:

=over

=item 1. 

The user enters their OpenID into a field on the consumer's
site, and hits a login button.

=item 2.

The consumer site discovers the user's OpenID server using
the YADIS protocol.

=item 3.

The consumer site sends the browser a redirect to the
identity server.  This is the authentication request as
described in the OpenID specification.

=item 4.

The identity server's site sends the browser a redirect
back to the consumer site.  This redirect contains the
server's response to the authentication request.

=back

The most important part of the flow to note is the consumer's site
must handle two separate HTTP requests in order to perform the
full identity check.

=head2 LIBRARY DESIGN

This consumer library is designed with that flow in mind.  The
goal is to make it as easy as possible to perform the above steps
securely.

At a high level, there are two important parts in the consumer
library.  The first important part is this module, which contains
the interface to actually use this library.  The second is the
L<Net::OpenID::JanRain::Stores|Net::OpenID::JanRain::Stores> module,
which describes the
interface to use if you need to create a custom method for storing
the state this library needs to maintain between requests.

In general, the second part is less important for users of the
library to know about, as several implementations are provided
which cover a wide variety of situations in which consumers may
use the library.

This module contains a class, C<Net::OpenID::JanRain::Consumer>, with methods
corresponding to the actions necessary in each of steps 2, 3, and
4 described in the overview.  Use of this library should be as easy
as creating a Consumer instance and calling the methods
appropriate for the action the site wants to take.

=head2 STORES AND DUMB MODE

OpenID is a protocol that works best when the consumer site is
able to store some state.  This is the normal mode of operation
for the protocol, and is sometimes referred to as smart mode.
There is also a fallback mode, known as dumb mode, which is
available when the consumer site is not able to store state.  This
mode should be avoided when possible, as it leaves the
implementation more vulnerable to replay attacks.

The mode the library works in for normal operation is determined
by the store that it is given.  The store is an abstraction that
handles the data that the consumer needs to manage between http
requests in order to operate efficiently and securely.

Several store implementation are provided, and the interface is
fully documented so that custom stores can be used as well.  See
L<Net::OpenID::JanRain::Stores> for more
information on the interface for stores.  The implementations that
are provided allow the consumer site to store the necessary data
in several different ways, including several SQL databases and
normal files on disk.

There is an additional concrete store provided that puts the
system in dumb mode.  This is not recommended, as it removes the
library's ability to stop replay attacks reliably.  It still uses
time-based checking to make replay attacks only possible within a
small window, but they remain possible within that window.  This
store should only be used if the consumer site has no way to
retain data between requests at all.

=head2 IMMEDIATE MODE

In the flow described above, the user may need to confirm to the
identity server that it's ok to authorize his or her identity.
The server may draw pages asking for information from the user
before it redirects the browser back to the consumer's site.  This
is generally transparent to the consumer site, so it is typically
ignored as an implementation detail.

There can be times, however, where the consumer site wants to get
a response immediately.  When this is the case, the consumer can
put the library in immediate mode.  In immediate mode, there is an
extra response possible from the server, which is essentially the
server reporting that it doesn't have enough information to answer
the question yet.  In addition to saying that, the identity server
provides a URL to which the user can be sent to provide the needed
information and let the server finish handling the original
request.

=head2 USING THIS LIBRARY

Integrating this library into an application is usually a
relatively straightforward process.  The process should basically
follow this plan:

Add an OpenID login field somewhere on your site.  When an OpenID
is entered in that field and the form is submitted, it should make
a request to the your site which includes that OpenID URL.

First, the application should instantiate the 
C<Net::OpenID::JanRain::Consumer> class
using the store of choice.  You may also pass a L<CGI::Session|CGI::Session> object
to the constructor, which will store user transaction data.

Next, the application should call the 'begin' method on the
C<Consumer> instance.  This method takes the OpenID URL.  The
L</begin> method returns an L</Net::OpenID::JanRain::Consumer::AuthRequest>
object.

Next, the application should call the
L</redirectURL> method on the
L</Net::OpenID::JanRain::Consumer::AuthRequest> object.
The parameter C<return_to> is the URL
that the OpenID server will send the user back to after attempting
to verify his or her identity.  The C<trust_root> parameter is the
URL (or URL pattern) that identifies your web site to the user
when he or she is authorizing it.  Send a redirect to the
resulting URL to the user's browser.

That's the first half of the authentication process.  The second
half of the process is done after the user's ID server sends the
user's browser a redirect back to your site to complete their
login.

When that happens, the user will contact your site at the URL
given as the C<return_to> URL to the
L</redirectURL> call made
above.  The request will have several query parameters added to
the URL by the identity server as the information necessary to
finish the request.

Get an C<Consumer> instance, and call its
L</complete> method, passing in all the
received query arguments.

If that call is successful, the user is authenticated.

=cut

use Carp;
use URI;
use Net::OpenID::JanRain::Util qw( findAgent normalizeUrl );
use Net::Yadis;

my $OPENID_NS = "http://openid.net/xmlns/1.0";
my $OPENID_SERVICE_TYPE = "http://openid\\.net/signon/1\\.[012]";
my $TOKEN_KEY = '_openid_consumer_token';
my $ENDPOINTS_KEY = '_openid_consumer_endpoints';

=head1 Methods of Net::OpenID::JanRain::Consumer 

=head2 new

 $consumer = Net::OpenID::JanRain::Consumer->new($session, $store);

=head3 arguments

=over

=item session

Must be an instance of L<CGI::Session|CGI::Session>.  Used to store user-specific
transaction data, including a list of openid services found in the
user's Yadis file, allowing fallback if the primary service is down.
Currently required, but may be made optional.

=item store

Must be an instance of L<Net::OpenID::JanRain::Stores|Net::OpenID::JanRain::Stores>, and is used
to store association and nonce data.

=back

=cut

sub new {
    my $caller = shift;
    my $session = shift || die "OpenID consumer needs a session";
    my $store = shift || die "OpenID consumer needs a store";
    my $class = ref($caller) || $caller;

    my $self = {
        session => $session,
        consumer => Net::OpenID::JanRain::GenericConsumer->new($store),
        };

    bless ($self, $class);
}

=head2 begin

=head3 Argument

=over

=item user_url

The url entered by a user, as on a web form.  This url will be canonicalized,
prepending C<http://> if it is not present.

=back

=head3 Returns

Returns an instance of either
L</Net::OpenID::JanRain::Consumer::FailureResponse> (upon failure)
or L</Net::OpenID::JanRain::Consumer::AuthRequest> if the initial steps
of the protocol succeeded.

=cut

sub begin {
    my ($self, $user_url) = @_;

    my $endpointlist = $self->{session}->param($ENDPOINTS_KEY);
    unless($endpointlist) {
	my $openid_url = normalizeUrl($user_url);
	my $foo;
	($foo, $endpointlist) = discover($openid_url);
	if (defined $endpointlist) {
	    $openid_url = $foo;
	}
	else {
	    return $failureResponseClass->new($openid_url, $foo);
	}
    }

    my $endpoint = shift @$endpointlist;

    if(@$endpointlist == 0) {
	$self->{session}->clear([$ENDPOINTS_KEY]);
    }
    else {
	$self->{session}->param($ENDPOINTS_KEY, $endpointlist);
    }
    return $self->beginWithoutDiscovery($endpoint);
}

sub discover {
    my $uri = shift or carp "Cannot discover nothing";
    my $filter = shift;

    my $yadis;
    eval {
        $yadis = Net::Yadis->discover($uri);
    };
    if ($@) {
        # openid_log("Yadis discovery failed: $@");
        my ($one, $two) = old_school_discover($uri);
        if(defined($two)) {
            return ($one, $two);
        }
        else {
            return ($@, undef);
        }
    }

    my $id_url = $yadis->url;
    
    $filter = sub {
        my $service = shift;
        
        $service->is_type($OPENID_SERVICE_TYPE) || return undef;
        
        my $endpoint = Net::OpenID::JanRain::Consumer::ServiceEndpoint->new;

        $endpoint->{delegate} = $service->findTag('Delegate', $OPENID_NS);
        $endpoint->{server_url} = $service->uri;
        $endpoint->{type_uris} = [$service->types];
        
        return $endpoint;
    } unless defined($filter);

    my @openid_endpoints = $yadis->filter_services($filter);

    # for convenience, although it's weird to do this
    foreach $endpoint (@openid_endpoints) {
        $endpoint->{identity_url} = $id_url; 
    }

    return ("Found no OpenID services", undef) unless @openid_endpoints;

    return ($id_url, \@openid_endpoints);
}

sub old_school_discover {
    my $uri = shift;

    my $ua = findAgent()->new;
    my $resp = $ua->get($uri);
    return ("Could not fetch $uri", undef) unless $resp->is_success;
    my $id_url = $resp->base; # follow redirects
    my $html = $resp->content;
    
    my $endpoint = Net::OpenID::JanRain::Consumer::ServiceEndpoint->fromHTML($id_url, $html);
    return ("Fallback on link tag failed", undef) unless $endpoint;
    return ($id_url, [$endpoint]);
}

sub beginWithoutDiscovery {
    my ($self, $endpoint) = @_;
    my $auth_req = $self->{consumer}->begin($endpoint);
    $self->{session}->param($TOKEN_KEY, $auth_req->token);
    return $auth_req;
}

=head2 complete

=head3 Argument

=over

=item query

Pass this method the query on the return_to url as a hash ref. 
Common ways to get this are C<CGI::Vars> and 
C<URI::QueryParam::query_form_hash>

=back

=head3 Returns

An instance of one of the following objects.  They all support the
'status' method.

=over

=item L</Net::OpenID::JanRain::Consumer::SuccessResponse>

=item L</Net::OpenID::JanRain::Consumer::FailureResponse>

=item L</Net::OpenID::JanRain::Consumer::CancelResponse>

=item L</Net::OpenID::JanRain::Consumer::SetupNeededResponse>

=back

=cut

sub complete {
    my ($self, $query) = @_;

    my $token = $self->{session}->param($TOKEN_KEY);

    my $response;
    unless(defined($token)) {
        $response = $failureResponseClass->new(undef, "Token not found in session");
    }
    else {
        $response = $self->{consumer}->complete($query, $token);
        $self->{session}->clear([$TOKEN_KEY]);
    }
    if( ($response->status eq 'success' or $response->status eq 'cancel')
         and defined($response->identity_url) )
    {
	# Clean up the session - we're done.
	$self->{session}->clear([$ENDPOINTS_KEY]);
    }
    return $response;
}
sub _normalizeUrl {
    my $url = shift;
    defined($url) or return undef;
    $url = "http://$url" unless($url =~ m#^\w+://#);
    return(URI->new($url)->canonical);
} 

package DiffieHellmanConsumerSession;

use Crypt::DH;

use Net::OpenID::JanRain::Util( fromBase64 );
use Net::OpenID::JanRain::CryptUtil qw( DEFAULT_DH_MOD
                                        DEFAULT_DH_GEN
                                        numToBase64
					base64ToNum
					numToBytes
					sha1
					);
sub session_type {
    return 'DH-SHA1';
}

sub new {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $dh = shift;
    
    my $default_dh = 0;
    
    unless($dh) {
        $dh = Crypt::DH->new(p => DEFAULT_DH_MOD, g=> DEFAULT_DH_GEN);
        $default_dh = 1;
    }
    
    unless($dh->isa('Crypt::DH')) {
        die "Attempt to instantiate DiffieHellmanConsumerSession with something not a Crypt::DH"
    }
    $dh->generate_keys;
    
    my $self = {
                dh => $dh,
                default_dh => $default_dh,
                };

    bless($self, $class);
}

sub dh {
    my $self = shift;
    return $self->{dh};
}

sub request {
    my $self = shift;
    my $cpub = numToBase64($self->dh->pub_key);
    
    my $args = {'openid.dh_consumer_public' => $cpub};

    unless($self->{default_dh}) {
        $args->{'openid.dh_modulus'} = numToBase64($self->dh->p);
        $args->{'openid.dh_gen'} = numToBase64($self->dh->g);
    }
    return $args;
}

sub extractSecret {
    my ($self, $response) = @_;

    my $spub = base64ToNum($response->{'dh_server_public'});
    my $dh_secret = $self->dh->compute_secret($spub);
    my $enc_mac_key = fromBase64($response->{'enc_mac_key'});
    return ($enc_mac_key ^ sha1(numToBytes($dh_secret)));
}

package PlainTextConsumerSession;

use Net::OpenID::JanRain::Util( fromBase64 );


sub session_type {
    return undef;
}

sub new {
    bless {};
}

sub request {
    return {};
}

sub extractSecret {
    my ($self, $response) = @_;
    return fromBase64($response->{'mac_key'});
}

package Net::OpenID::JanRain::Consumer::ServiceEndpoint;

use Net::OpenID::JanRain::Consumer::LinkParser qw( parseOpenIDLinkRel );

sub new {
    my $caller = shift;
    my $class = ref($caller) || $caller;

    my $self = {
            type_uris => [],
        };

    bless($self, $class);
}

sub fromHTML {
    my ($caller, $uri, $html) = @_;

    my ($delegate_url, $server_url) = parseOpenIDLinkRel($html);
    unless (defined($server_url)) {
	# warn "Could not find link tag";
	return undef;
    }
    my $service = $caller->new;
    $service->{identity_url} = $uri;
    $service->{delegate} = $delegate_url;
    $service->{server_url} = $server_url;
    $service->{type_uris} = [OPENID_1_0_TYPE];
    return $service;
}

sub usesExtension {
    my ($self, $extension_uri) = @_;
    foreach (@{$self->{type_uris}}) {
        return 1 if $_ eq $extension_uri;
    }
    return 0;
}

sub server_id {
    my $self = shift;
    return $self->{delegate} || $self->{identity_url};
}

sub identity_url {
    my $self = shift;
    return $self->{identity_url};
}

sub server_url {
    my $self = shift;
    return $self->{server_url};
}

package Net::OpenID::JanRain::GenericConsumer;

use warnings;
use strict;

use Carp;
use URI;
use URI::QueryParam;
use Net::OpenID::JanRain::Util qw(
    appendArgs
    toBase64
    fromBase64
    kvToHash
    hashToKV
    findAgent
    );

use Net::OpenID::JanRain::CryptUtil qw(
    randomString
    hmacSha1
    sha1
    numToBase64
    base64ToNum
    numToBytes
    bytesToNum
    );

use Net::OpenID::JanRain::Consumer::LinkParser qw(parseLinkAttrs);

require Net::OpenID::JanRain::Association;
require Crypt::DH;

# Parse a query, returning the openid parameters, removing
# the 'openid.' prefix from the keys
sub getOpenIDParameters {
    my ($query) = @_;
    my %params;
    while(my ($k, $v) = each(%$query)) {
        if($k =~ m/^openid\./) {
            $params{$k} = $v;
        }
    }
    return(%params);
} # end getOpenIDParameters
########################################################################

my $NONCE_LEN = 8;
my $NONCE_CHRS = join("", 'a'..'z', 'A'..'Z', 0..9);
# Maximum time for a transaction: 5 minutes
my $TOKEN_LIFETIME = 60 * 5; 

sub new {
    my $caller = shift;
    my $store = shift;
    my $fetcher = shift;
    my $class = ref($caller) || $caller;
    unless (defined($store)) {
        die "Cannot instantiate OpenID consumer without a store";
    }
    unless (defined($fetcher)) {
        my $agentClass = findAgent();
        $fetcher = $agentClass->new;
    }
    my $self = {
        store     => $store,
	fetcher	  => $fetcher
        };
    bless($self, $class);
} # end new
########################################################################
my $authRequestClass = "Net::OpenID::JanRain::Consumer::AuthRequest";
sub begin {
    my $self = shift;
    my ($service_endpoint) = @_;
    return undef unless $service_endpoint;

    my $nonce = $self->_createNonce();
    my $token = $self->_genToken($service_endpoint->identity_url,
                          $service_endpoint->server_id,
                          $service_endpoint->server_url);
    my $assoc = $self->_getAssociation($service_endpoint->server_url);
    my $request = $authRequestClass->new($token, $assoc, $service_endpoint);
    $request->addReturnToArg('nonce', $nonce);
    return $request;
}

########################################################################

sub complete {
    my $self = shift;
    my ($query, $token) = @_;
    my $mode = $query->{'openid.mode'};
    my ($identity_url, $server_id, $server_url) = $self->_splitToken($token);
    
    if($mode eq 'cancel') {
        return $cancelResponseClass->new($identity_url);
    }
    elsif($mode eq 'error') {
        my $error = $query->{'openid.error'};
        return $failureResponseClass->new($identity_url, $error);
    }
    elsif($mode eq 'id_res') {
        return $failureResponseClass->new($identity_url,
            "No session state found") unless $identity_url;
    
        my $response = $self->_doIdRes($query, $identity_url, $server_id, $server_url);
        if ($response->status eq 'success') {
            return $self->_checkNonce($response, $query->{nonce}) 
        }
        else {
            return $response;
        }
    }
    else {
        return $failureResponseClass->new($identity_url, "Invalid mode: $mode");
    }
} # end complete

sub _checkNonce {
    my ($self, $response, $nonce) = @_;

    my $rt_uri = URI->new($response->return_to);
    my $query = $rt_uri->query_form_hash;
    while( my ($k, $v) = each %$query) {
        if ($k eq 'nonce') {
            if ($v eq $nonce) {
                if ($self->store->useNonce($nonce)) {
                    return $response;
                }
                else {
                    return $failureResponseClass->new($response->identity_url,
                                    "Nonce not found in store");
                }
            }
            else {
                return $failureResponseClass->new($response->identity_url,
                                "Nonce mismatch");
            }
        }
    }
    return $failureResponseClass->new($response->identity_url,
                    "Nonce missing from return_to: ".$response->return_to);
}

sub _createNonce {
    my $self = shift;
    my $nonce = randomString($NONCE_LEN, $NONCE_CHRS);
    $self->store->storeNonce($nonce);
    return $nonce;
}

sub _doIdRes {
    my $self = shift;
    my ($query, $consumer_id, $server_id, $server_url) = @_;

    my $user_setup_url = $query->{'openid.user_setup_url'};
    return $setupNeededResponseClass->new($consumer_id, $user_setup_url) if $user_setup_url;
    
    my $return_to = $query->{'openid.return_to'};
    my $server_id2 = $query->{'openid.identity'};
    my $assoc_handle = $query->{'openid.assoc_handle'};

    unless($return_to and $server_id and $assoc_handle) {
	my $missing_fields = '';
	$missing_fields .= 'return_to,' unless $return_to;
	$missing_fields .= 'server_id,' unless $server_id;
	$missing_fields .= 'assoc_handle' unless $assoc_handle;

        return $failureResponseClass->new($consumer_id, "Missing required fields $missing_fields");
    }
    unless($server_id eq $server_id2) {
        return $failureResponseClass->new($consumer_id,
                        "Server ID mismatch: query($server_id2) token($server_id)");
    }
    my $assoc = $self->store->getAssociation($server_url, $assoc_handle);

    if(not $assoc) { # We don't know this association - we must do check_auth
        if ($self->_checkAuth($consumer_id, $query, $server_url)) {
            return $successResponseClass->fromQuery($consumer_id, $query);
        }
        else {
            return $failureResponseClass->new($consumer_id, 
                            "Check_authentication Failed");
        }
    }
    if($assoc->expiresIn == 0) { # expired assoc.  Redo from start.
        return $failureResponseClass->new($consumer_id,
                        "Association with $server_url expired.");
    }
    # Assoc is good - check the signature
    my $sig = $query->{'openid.sig'};
    my $signed = $query->{'openid.signed'}; 
    if((not $sig) or (not $signed)) {
        return $failureResponseClass->new($consumer_id, 
                    "Signature missing from id_res parameters");
    }

    my @signed_list = split(',', $signed);
    my $v_sig = $assoc->signHash($query, \@signed_list, 'openid.');
    if ($v_sig ne $sig) {
        return $failureResponseClass->new($consumer_id,
                        "Signature Mismatch!");
    }
    return $successResponseClass->fromQuery($consumer_id, $query);
} # end _doIdRes
########################################################################
sub _checkAuth {
    my $self = shift;
    my ($consumer_id, $query, $server_url) = @_;
    my $request = $self->_createCheckAuthRequest($query);
    return undef unless $request;
    my $response = $self->{fetcher}->post($server_url, $request);
    return undef unless $response;
    return $self->_processCheckAuthResponse($response, $server_url);
} # end _checkAuth

sub _createCheckAuthRequest {
    my ($self, $query) = @_;
    my $signed = $query->{'openid.signed'};
    unless ($signed) {
        carp "Signed list empty; check_authentication aborted";
        return undef;
    }
    my @check_fields = split /,/, $signed;
    push @check_fields, ('assoc_handle', 'sig', 'signed', 'invalidate_handle');
    my $check_args = {};
    for my $field (@check_fields) {
        $check_args->{'openid.'.$field} = $query->{'openid.'.$field}
            if defined($query->{'openid.'.$field});
    }
    $check_args->{'openid.mode'} = 'check_authentication';
    return $check_args;
}

sub _processCheckAuthResponse {
    my ($self, $response, $server_url) = @_;

    my $hr = kvToHash($response->content);
    
    my $is_valid = $hr->{'is_valid'};

    my $invalidate_handle = $response->{'invalidate_handle'};

    $self->store->removeAssociation($server_url, $invalidate_handle)
        if defined($invalidate_handle);

    return 1 if $is_valid eq 'true';

    warn "Server $server_url responded to check_auth with is_valid:$is_valid";
    return 0;
}
########################################################################

########################################################################
sub _genToken {
    my $self = shift;
    my ($consumer_id, $server_id, $server_url) = @_;
    my $joined = join("\x00", time, $consumer_id, $server_id, $server_url);
    my $sig = hmacSha1($self->store->getAuthKey, $joined);
    return(toBase64($sig.$joined));
} # end _genToken
########################################################################
sub _splitToken {
    my $self = shift;
    my ($token) = @_;
    carp "trying to split undef" unless defined $token;
    $token = fromBase64($token);
    return() if(length($token) < 20);
    my ($sig, $joined) = (substr($token, 0, 20), substr($token, 20));
    return() if(hmacSha1($self->store->getAuthKey, $joined) ne $sig);
    my @s = split(/\x00/, $joined);
    return() if(@s != 4);
    my ($timestamp, $consumer_id, $server_id, $server_url) = @s;
    return() if($timestamp == 0 or 
        (($timestamp + $TOKEN_LIFETIME) < time)
        );
    return($consumer_id, $server_id, $server_url);
} # end _splitToken

sub _getAssociation {
    my $self = shift;
    my ($server_url, $replace) = @_;
    $replace ||= 0;
    $self->store->isDumb and return();
    my $assoc = $self->store->getAssociation($server_url);
    unless ($assoc and $assoc->expiresIn > $TOKEN_LIFETIME) {
        my ($assoc_session, $args) = $self->_createAssociateRequest($server_url);
        my $response = $self->{fetcher}->post($server_url, $args);
        return undef unless $response;
	my $results = kvToHash($response->content);
        $assoc = $self->_parseAssociation($results, $assoc_session, $server_url);
    }
    return $assoc;
} # end _getAssociation

sub _createAssociateRequest {
    my ($self, $server_url) = @_;
    my $sessionClass;
    if ($server_url =~ /^https:/) {
        $sessionClass = 'PlainTextConsumerSession';
    }
    else {
        $sessionClass = 'DiffieHellmanConsumerSession';
    }
    my $assoc_session = $sessionClass->new;

    my $args = {
        'openid.mode' => 'associate',
        'openid.assoc_type' => 'HMAC-SHA1',
        };
    
    $args->{'openid.session_type'} = $assoc_session->session_type
            if $assoc_session->session_type;

    my $request = $assoc_session->request;
    while (my ($k, $v) = each %$request) {
        $args->{$k} = $v;
    }
    return $assoc_session, $args;
}

sub _parseAssociation {
    my ($self, $results, $assoc_session, $server_url) = @_;

    #XXX logging
    my $assoc_type = $results->{assoc_type} or return undef;
    my $assoc_handle = $results->{assoc_handle} or return undef;
    my $expires_in_str = $results->{expires_in} or return undef;
    
    return undef unless $assoc_type eq 'HMAC-SHA1';
    my $expires_in = int($expires_in_str) or return undef;

    my $session_type = $results->{session_type} || 'plaintext';
    unless ($session_type eq $assoc_session->session_type) {
        if($session_type eq 'plaintext' ) { 
            warn "Falling back to plaintext assoc session from ".
                $assoc_session->session_type;
            $assoc_session = PlainTextConsumerSession->new;
        }
        else {
            warn "Session type mismatch. Expected ".$assoc_session->session_type.
                    "; got $session_type";
            return undef;
        }
    }
    my $secret = $assoc_session->extractSecret($results) or return undef;
    
    my $assoc = Net::OpenID::JanRain::Association->fromExpiresIn($expires_in,
                    $assoc_handle, $secret, $assoc_type);
    $self->store->storeAssociation($server_url, $assoc);
    
    return $assoc;
}

sub store {
    my $self = shift;
    return $self->{store};
}

package Net::OpenID::JanRain::Consumer::AuthRequest;

use warnings;
use strict;
use Net::OpenID::JanRain::Util qw( appendArgs );

=head1 Net::OpenID::JanRain::Consumer::AuthRequest

An instance of this class is returned by the C<begin> method of the
C<Net::OpenID::JanRain::Consumer> object when fetching the identity URL
succeeded.

=head2 Methods

=head3 status

returns 'in_progress'

=cut

sub new {
    my $caller = shift;
    my ($token, $assoc, $endpoint) = @_;
    my $class = ref($caller) || $caller;
    my $self = {
        token           => $token,
        endpoint        => $endpoint,
        assoc           => $assoc,
        extra_args      => {},
        return_to_args  => {},
        };
    bless($self, $class);
    return($self);
} 

sub token {
    my $self = shift;
    return $self->{token};
}

sub endpoint {
    my $self = shift;
    return $self->{endpoint};
}

sub assoc {
    my $self = shift;
    return $self->{assoc};
}

sub extra_args {
    my $self = shift;
    return $self->{extra_args};
}

sub return_to_args {
    my $self = shift;
    return $self->{return_to_args};
}

=head3 addExtensionArg

 $auth_req->addExtensionArg($namespace, $key, $value);

Add an extension argument to the openid request.

=head4 Arguments

=over

=item namespace

A namespace string, for example C<'sreg'>.

=item key

The name of the argument.

=item value

The contents of the argument.

=back

=cut

sub addExtensionArg {
    my ($self, $namespace, $key, $value) = @_;

    my $arg_name = join '.', ('openid', $namespace, $key);
    $self->{extra_args}->{$arg_name} = $value;
}

sub addReturnToArg {
    my ($self, $key, $value) = @_;

    $self->{return_to_args}->{$key} = $value;
}

=head2 redirectURL

 $url = $auth_req->redirectURL($trust_root, $return_to, $immediate);

This method returns a URL on the user's OpenID server to redirect the
user agent to.

=head3 Arguments

=over

=item trust_root

Provide the trust root for your site.  The return_to URL must descend
from this trust root.

=item return_to

This is the URL that the server will redirect the user back to after
authenticating.

=item immediate

This is an optional flag to use immediate mode, which indicates to the
server that if the authentication is not possible without user
interaction, the user agent should be redirected back immediately instead
of displaying a page to do the required login or approval.  Use this flag
if you are performing this request behind the scenes, as in a hidden IFRAME.

=back

=cut

sub redirectURL {
    my $self = shift;
    my $trust_root = shift;
    my $return_to = shift;
    my $immediate = shift;

    my $mode;
    if($immediate) {
        $mode = 'checkid_immediate';
    }
    else {
        $mode = 'checkid_setup';
    }

    $return_to = appendArgs($return_to, $self->return_to_args);
    
    my $redir_args = {
        'openid.mode'       => $mode,
        'openid.identity'   => $self->endpoint->server_id,
        'openid.return_to'  => $return_to,
        'openid.trust_root' => $trust_root,
        };

    if ($self->assoc) {
        $redir_args->{'openid.assoc_handle'} = $self->assoc->handle;
    }
    
    while( my ($k, $v) = each %{$self->extra_args}) {
        $redir_args->{$k} = $v;
    }
    return appendArgs($self->endpoint->server_url, $redir_args);
}

sub status {
    return 'in_progress';
}

package Net::OpenID::JanRain::Consumer::SuccessResponse;

=head1 Net::OpenID::JanRain::Consumer::SuccessResponse

This object is returned by the L</complete> method of
C<Net::OpenID::JanRain::Consumer> when the authentication
was successful.

=head2 Methods

=head3 extensionResponse

Pass this method an extension prefix, and it will return a hash ref
with the parameters recieved for that extension.  For example, if
the server sent the following response:

 openid.mode=id_res
 openid.identity=http://bobdobbs.com/
 openid.signed=[whatever]
 openid.sig=[whatever]
 openid.assoc_handle=[whatever]
 openid.return_to=[whatever]
 openid.sreg.fullname=Bob Dobbs
 openid.sreg.language=AQ

Then once we had the success response we could do:

 $response->extensionResponse('sreg');
 --> {'fullname' => "Bob Dobbs", 'language' => 'AQ'}

=head3 identity_url

Returns the identity URL verified.

=head3 return_to

Returns the signed openid.return_to argument.

=head3 status

Returns 'success'.

=cut

sub new {
    my ($caller, $identity_url, $signed_args) = @_;
    my $class = ref($caller) || $caller;
    my $self = { identity_url => $identity_url,
                 signed_args  => $signed_args,
                 };
    bless($self,$class);
}

sub fromQuery {
    my ($caller, $identity_url, $query) = @_;
    my @signed = split /,/,$query->{'openid.signed'};
    my $signed_args = {};
    foreach my $field (@signed) {
        $field = "openid.$field";
        $signed_args->{$field} = $query->{$field};
    }
    return $caller->new($identity_url, $signed_args);
}

sub extensionResponse {
    my ($self, $prefix) = @_;
    my $response = {};
    $prefix = "openid.$prefix.";
    while ( my ($k, $v) = each %{$self->{signed_args}}) {
        if($k =~ /^$prefix(.+)$/) {
            $response->{$1} = $v;
        }
    }
    return $response;
}

sub identity_url {
    my $self = shift;
    return $self->{identity_url};
}

sub return_to {
    my $self = shift;
    return $self->{signed_args}->{'openid.return_to'};
}

sub status {
    return 'success';
}

package Net::OpenID::JanRain::Consumer::FailureResponse;

=head1 Net::OpenID::JanRain::Consumer::FailureResponse

An instance of this class may be returned by the L</begin> or L</complete>
methods of the C<Net::OpenID::JanRain::Consumer>.  It indicates protocol
failure.

=head2 Methods

=head3 status

returns 'failure'

=head3 identity_url

returns the identity url in question.

=head3 message

returns a message describing the failure.


=cut

sub new {
    my ($caller,$identity_url, $message) = @_;

    my $self = { identity_url => $identity_url,
                 message => $message,
                 };
    my $class = ref($caller) || $caller;
    bless($self,$class);
}

sub status {
    return 'failure';
}

sub identity_url {
    my $self = shift;
    return $self->{identity_url};
}

sub message {
    my $self = shift;
    return $self->{message};
}

package Net::OpenID::JanRain::Consumer::CancelResponse;

=head1 Net::OpenID::JanRain::Consumer::CancelResponse

This object is returned by the L</complete> method of
C<Net::OpenID::JanRain::Consumer> when a cancel response was
recieved from the server, indicating that the user did not
complete the authentication process.

=head2 Methods

=head3 status

returns 'cancel'

=head3 identity_url

returns the identity url of the request, if available.

=cut

sub new {
    my $caller = shift;
    my $identity_url = shift;
    my $self = {identity_url => $identity_url};

    my $class = ref($caller) || $caller;
    bless($self,$class);
}

sub status {
    return 'cancel';
}

sub identity_url {
    my $self = shift;
    return $self->{identity_url};
}

package Net::OpenID::JanRain::Consumer::SetupNeededResponse;

=head1 Net::OpenID::JanRain::Consumer::SetupNeededResponse

An instance of this class is returned by the L</complete> method of
C<Net::OpenID::JanRain::Consumer> when an immediate mode request
was not successful.  You must instead use non-immediate mode.  A URL
to send the user to is provided.

=head2 Methods

=head3 status

returns 'setup_needed'

=head3 setup_url

returns the setup url, where you may redirect the user to complete 
authentication.

=head3 identity_url

returns the identity url in question.

=cut

sub new {
    my $caller = shift;
    my $identity_url = shift;
    my $setup_url = shift;
    
    my $self = {identity_url => $identity_url,
                setup_url => $setup_url};

    my $class = ref($caller) || $caller;
    bless($self,$class);
}

sub status {
    return 'setup_needed';
}

sub setup_url {
    my $self = shift;
    return $self->{setup_url};
}

sub identity_url {
    my $self = shift;
    return $self->{identity_url};
}

1;
