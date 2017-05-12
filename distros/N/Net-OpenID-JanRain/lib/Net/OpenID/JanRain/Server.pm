=head1 OVERVIEW

An OpenID server must perform three tasks:

=over

=item 1.

Examine the incoming request to determine its nature and validity.

=item 2.

Make a decision about how to respond to this request.

=item 3.

Format the response according to the protocol.

=back

The first and last of these tasks may performed by
the L</decodeRequest> and
L</encodeResponse> methods of the
Server object.  Who gets to do the intermediate task -- deciding
how to respond to the request -- will depend on what type of request it
is.

If it's a request to authenticate a user (a C<checkid_setup> or
C<checkid_immediate> request), you need to decide if you will assert
that this user may claim the identity in question.  Exactly how you do
that is a matter of application policy, but it generally involves making
sure the user has an account with your system and is logged in, checking
to see if that identity is hers to claim, and verifying with the user that
she does consent to releasing that information to the party making the
request.

Examine the properties of the L</CheckIDRequest> object, and if
and when you've come to a decision, form a response by calling
C<</CheckIDRequest->answer>>.

Other types of requests relate to establishing associations between client
and server and verifying the authenticity of previous communications.
The Server instance contains all the logic and data necessary to
respond to
such requests; just pass it to the L</handleRequest> method.

=head2 OpenID Extensions

Do you want to provide other information for your users
in addition to authentication?  Version 1.2 of the OpenID
protocol allows consumers to add extensions to their requests.
For example, with sites using the L<Simple Registration Extension|http://www.openidenabled.com/openid/simple-registration-extension/>,
a user can agree to have their nickname and e-mail address sent to a
site when they sign up.

Since extensions do not change the way OpenID authentication works,
code to handle extension requests may be completely separate from the
L</OpenIDRequest> class here.  But you'll likely want data sent back by
your extension to be signed.  L</OpenIDResponse> provides methods with
which you can add data to it which can be signed with the other data in
the OpenID signature.

For example:

    # when request is a checkid_* request
    response = request.answer(True)
    # this will a signed 'openid.sreg.timezone' parameter to the response
    response.addField('sreg', 'timezone', 'America/Los_Angeles')

=head2 Stores

The OpenID server needs to maintain state between requests in order
to function.  Its mechanism for doing this is called a store.  The
store interface is defined in L<Net::OpenID::JanRain::Stores>.
Additionally, several concrete store implementations are provided, so that
most sites won't need to implement a custom store.  For a store backed
by flat files on disk, see L<Net::OpenID::JanRain::Stores::FileStore>.
For stores based on PostGreSQL, MySQL or SQLite, see the 
L<Net::OpenID::JanRain::Stores::SQLStore|Net::OpenID::JanRain::Stores::SQLStore>
module.

=cut

package Net::OpenID::JanRain::Server::Request;

use strict;
use warnings;
use Carp;

=head1 Net::OpenID::JanRain::Server::Request

The parent class for several types of requests.  None of these classes
are to be instantiated by the user, but this class will never
be encountered except as a parent.

=head2 Method

=head3 mode

Returns the C<openid.mode> parameter of this request.

=cut

my $errorClass = 'Net::OpenID::JanRain::Server::ProtocolError';

sub mode {
    my $self = shift;
    return $self->{mode};
}

package Net::OpenID::JanRain::Server::CheckAuthRequest;
our @ISA = qw( Net::OpenID::JanRain::Server::Request );
use Carp;
use strict;
use warnings;

use Net::OpenID::JanRain::Util qw( hashToPairs );

use constant {
    OPENID_PREFIX  =>  'openid.',
};

=head2 Net::OpenID::JanRain::Server::CheckAuthRequest

A request object for C<openid.mode=check_authentication>.
This request is best handled by the L</handleRequest> method of
the L</Net::OpenID::JanRain::Server> object.

However, it does possess an C<answer> method which takes a 
L</Net::OpenID::JanRain::Server::Signatory> object.

=cut

sub new {
    my ($caller, $assoc_handle, $sig, $signed) = @_;
    my $invalidate_handle = shift;

    my $class = ref($caller) || $caller;

    my $self = {
      mode              => 'check_authentication',
      assoc_handle      => $assoc_handle,
      sig               => $sig,
      signed            => $signed,
      invalidate_handle => $invalidate_handle,
    };

    bless($self, $class);
}

sub fromQuery {
    my ($caller, $query) = @_;

    my $assoc_handle = $query->{OPENID_PREFIX . 'assoc_handle'};
    my $sig = $query->{OPENID_PREFIX . 'sig'};
    my $signed_list = $query->{OPENID_PREFIX . 'signed'};
    my $invalidate_handle = $query->{OPENID_PREFIX . 'invalidate_handle'};

    unless (defined($assoc_handle) and 
            defined($sig) and 
            defined($signed_list)) {
        return $errorClass->new($query, "check_authentication request missing required parameters.");
    }
    
    my @signed_list = split ',', $signed_list;
    my %vq = %$query;
    $vq{OPENID_PREFIX . 'mode'} = 'id_res';

    my $signed_pairs = hashToPairs(\%vq, \@signed_list, OPENID_PREFIX);
    return $errorClass->new($query, "Query missing arg in signed list") unless $signed_pairs;
    
    my $self = {
                mode => 'check_authentication',
                assoc_handle => $assoc_handle,
                signed => $signed_pairs,
                sig => $sig,
                invalidate_handle => $invalidate_handle,
                };

    bless($self);
}

sub answer {
    my ($self, $signatory) = @_;

    my $is_valid = $signatory->verify($self->{assoc_handle}, $self->{sig}, $self->{signed});

    $signatory->invalidate($self->{assoc_handle}, 1);
    my $response = Net::OpenID::JanRain::Server::Response->new($self);
    $response->addFields('',{'is_valid' => (($is_valid and "true") or "false")});

    if ($self->{invalidate_handle}) {
        my $assoc = $signatory->getAssociation($self->{invalidate_handle}, 0);
        $response->addFields('',{'invalidate_handle' => $self->{invalidate_handle}}) unless $assoc;
    }
    return $response;
}


package Net::OpenID::JanRain::Server::AssociateRequest;
our @ISA = qw( Net::OpenID::JanRain::Server::Request );

use strict;
use warnings;
use Carp;
use Crypt::DH;
use Net::OpenID::JanRain::Util qw( toBase64 fromBase64 );
use Net::OpenID::JanRain::CryptUtil qw( base64ToNum
                                        numToBase64 
                                        numToBytes
                                        sha1
                                        DEFAULT_DH_MOD 
                                        DEFAULT_DH_GEN );

use constant {
    OPENID_PREFIX  =>  'openid.',
};

=head2 Net::OpenID::JanRain::Server::AssociateRequest

A request object for C<openid.mode=associate>.
This request is best handled by the L</handleRequest> method of
the L</Net::OpenID::JanRain::Server> object.

However, it does possess an C<answer> method which takes an
L<Net::OpenID::JanRain::Association|Net::OpenID::JanRain::Association>
object.  It also has accessor methods C<assoc_type> and C<session_type>.

=cut


sub new {
    my ($caller, $session_type, $pubkey);

    my $class = ref($caller) || $caller;
    
    my $self;
    if ($session_type eq 'DH-SHA1') {
        $self = {
            mode            => 'associate',
            session_type    => $session_type,
            pubkey          => $pubkey,
            dh              => Crypt::DH->new(p => DEFAULT_DH_MOD,
                                              g => DEFAULT_DH_GEN ),
        };
    }
    else {
        $self = {
            session_type    => $session_type,
        }
    }
    bless($self, $class);
}

sub fromQuery {
    my ($caller, $query) = @_;
    my $class = ref($caller) || $caller;


    my $assoc_type = $query->{OPENID_PREFIX . 'assoc_type'} || 'HMAC-SHA1';

    unless ($assoc_type eq 'HMAC-SHA1') {
        return $errorClass->new($query, "Unknown association type '$assoc_type'");
    }
    
    my $session_type = $query->{OPENID_PREFIX . 'session_type'};

    my $self = {};
    unless ($session_type) {
        $session_type = 'plaintext';
    }
    if ($session_type eq 'DH-SHA1') {
        my $raw_cpub = $query->{OPENID_PREFIX . 'dh_consumer_public'};
        unless ($raw_cpub) {
            return $errorClass->new($query, 
                    'DH-SHA1 associate request has no public key');
        }
        my $cpub = base64ToNum($raw_cpub); 
        unless (defined($cpub)) {
            return $errorClass->new($query, 
                    'DH public key improperly encoded');
        }        

        my $dh_modulus = $query->{OPENID_PREFIX . 'dh_modulus'};
        if (defined($dh_modulus)) {
            $dh_modulus = base64ToNum($dh_modulus);
            unless (defined($dh_modulus)) {
                 return $errorClass->new($query, 
                    'DH modulus improperly encoded');           
            }
        }
        else {
            $dh_modulus = DEFAULT_DH_MOD;
        }
        my $dh_gen = $query->{OPENID_PREFIX . 'dh_gen'};
        if (defined($dh_gen)) {
            $dh_gen = base64ToNum($dh_gen);
            unless (defined($dh_gen)) {
                 return $errorClass->new($query, 
                    'DH gen improperly encoded');           
            }
        }
        else {
            $dh_gen = DEFAULT_DH_GEN;
        }
        
        $self = {
            mode         => 'associate',
            session_type => 'DH-SHA1',
            assoc_type   => $assoc_type,
            pubkey       => $cpub,
            dh           => Crypt::DH->new(g => $dh_gen, p => $dh_modulus),
        };
    }
    elsif ($session_type eq 'plaintext') {
        $self = {
            mode         => 'associate',
            session_type => 'plaintext',
            assoc_type   => $assoc_type,
        }
    }
    else {
        return $errorClass->new($query, "Unknown session type '$session_type'");
    }
    bless($self, $class);
}

sub answer {
    my ($self, $assoc) = @_;
    
    my $response = Net::OpenID::JanRain::Server::Response->new($self);

    $response->addFields('',{
        assoc_handle    => $assoc->handle,
        expires_in      => $assoc->expiresIn(),
        assoc_type      => 'HMAC-SHA1',
        });
    if ($self->session_type eq 'DH-SHA1') {
        my $dh = $self->{dh};
        $dh->generate_keys;
        my $dh_secret = $dh->compute_secret($self->{pubkey});
        my $enc_mac_key = $assoc->{secret} ^ sha1(numToBytes($dh_secret));
        my $spub = $dh->pub_key;
        $response->addFields('',{
            session_type        => $self->session_type,
            dh_server_public    => numToBase64($spub),
            enc_mac_key         => toBase64($enc_mac_key),
            });
    }
    elsif ($self->session_type eq 'plaintext') {
        $response->addFields('',{mac_key => toBase64($assoc->secret)});
    }
    else {
    # XXX - kablooie
    }
    return $response;
}

sub session_type {
    my $self = shift;
    return $self->{session_type};
}

sub assoc_type {
    my $self = shift;
    return $self->{assoc_type};
}

package Net::OpenID::JanRain::Server::CheckIDRequest;
our @ISA = qw( Net::OpenID::JanRain::Server::Request );

use strict;
use warnings;
use URI;

use constant {
    OPENID_PREFIX  =>  'openid.',
};

=head2 Net::OpenID::JanRain::Server::CheckIDRequest

This object represents requests where C<openid.mode=checkid_setup> or
C<openid.mode=checkid_immediate>.  It is returned by the L</decodeRequest>
method of L<Net::OpenID::JanRain::Server>.

=head3 Methods

=cut

sub new {
    my ($caller, $identity, $return_to, $optional) = @_;
    my $trust_root = $optional->{trust_root};
    my $immediate = $optional->{immediate};
    my $assoc_handle = $optional->{assoc_handle};
    my $class = ref($caller) || $caller;

    my $self = {
        assoc_handle => $assoc_handle,
        identity     => $identity,
        return_to    => $return_to,
        trust_root   => $trust_root || $return_to,
    };
    if ($immediate) {
        $self->{immediate} = 1;
        $self->{mode} = 'checkid_immediate';
    }
    else {
        $self->{immediate} = 0;
        $self->{mode} = 'checkid_setup';
    }

    my ($tr_valid, $message) = 
            checkTrustRoot($self->{trust_root}, $self->{return_to});
    unless ($tr_valid) {
        carp $message;
        return undef;
    }

    bless($self, $class);
}

sub fromQuery {
    my ($caller, $query) = @_;
    my $class = ref($caller) || $caller;

    my $mode = $query->{OPENID_PREFIX.'mode'};
    my $self;
    if ($mode eq "checkid_immediate") {
        $self = {
            immediate   => 1,
            mode        => 'checkid_immediate',
            trust_root  => $query->{OPENID_PREFIX.'trust_root'} 
                            || $query->{OPENID_PREFIX.'return_to'},
            assoc_handle=> $query->{OPENID_PREFIX.'assoc_handle'},
        };
    }
    else {
        $self = {
            immediate   => 0,
            mode        => 'checkid_setup',
            trust_root  => $query->{OPENID_PREFIX.'trust_root'}
                            || $query->{OPENID_PREFIX.'return_to'},
            assoc_handle=> $query->{OPENID_PREFIX.'assoc_handle'},
        };
    }
    my @required = ('identity', 'return_to'); 

    for my $field (@required) {
        my $value = $query->{OPENID_PREFIX.$field};
        unless ($value) {
            return $errorClass->new($query, "$field is a required field for a $mode request");
        }
        $self->{$field} = $value;
    }

    my ($tr_valid, $message) = 
            checkTrustRoot($self->{trust_root}, $self->{return_to});
    return $errorClass->new($query, $message) unless $tr_valid;

    bless($self, $class);
}

=head4 answer

 $response = $request->answer($allow, $server_url);

=over

=item $allow

A boolean value: if true, sends an C<id_res> response.  If false,
sends a C<cancel> response if the request is not immediate, and
C<setup_needed> if it is immediate.

=item $server_url

This argument is required if the request is immediate, and should be the
URL of the server endpoint, used to construct the setup URL.

=back

=cut

sub answer {
    my $self = shift;
    my $allow = shift;
    my $server_url = shift;
    
    my $response = Net::OpenID::JanRain::Server::Response->new($self);
    
    if($allow) {
        $response->addFields('',{
            mode        => 'id_res',
            identity    => $self->identity,
            return_to   => $self->return_to,
            }, 1);
    }
    else {
        if ($self->immediate) {
            croak('server_url is required for allow=false in immediate mode')
                unless $server_url;
            # Make a new request just like me, but with immediate=False.
            my $setup_request = Net::OpenID::JanRain::Server::CheckIDRequest->new(
                    $self->identity, $self->return_to, $self->trust_root,
                    0, $self->assoc_handle);
            my $setup_url = $setup_request->encodeToURL($server_url);
            $response->addFields('',{ mode           => 'id_res',
                                      user_setup_url => $setup_url
                                    }, 0); # unsigned
        }
        else {
            $response->addFields('',{mode => 'cancel'},0); # unsigned
        }
    }
    return $response;
}

=head3 encodeToURL

Takes the server endpoint URL and returns a URL which would generate this
request.

=cut

sub encodeToURL {
    my ($self, $server_url) = @_;
    
    my $q = {
        OPENID_PREFIX.'mode'        => $self->mode,
        OPENID_PREFIX.'identity'    => $self->identity,
        OPENID_PREFIX.'return_to'   => $self->return_to
        };
    $q->{OPENID_PREFIX.'trust_root'} = $self->trust_root if $self->trust_root;
    $q->{OPENID_PREFIX.'assoc_handle'} = $self->assoc_handle if $self->assoc_handle;
    
    return appendArgs($server_url, $q);
}

=head3 getCancelURL

Returns a URL to redirect the user to send a cancel message to the consumer.
Calling this method will cause croakage if the request is in immediate mode.

=cut

sub getCancelURL {
    my $self = shift;

    croak('Cancel is not an appropriate response to an immediate mode request') if $self->immediate;

    return appendArgs($self->return_to, {OPENID_PREFIX.'mode'=>'cancel'});
}

=head3 checkTrustRoot

 $is_return_to_valid_against_trust_root = checkTrustRoot($trust_root, $return_to);

=cut

# in Util now, maybe should be removed?
sub checkTrustRoot {
    my ($trust_root, $return_to) = @_;

    my $rt = URI->new($return_to);
    my $tr = URI->new($trust_root);
    
    return 0, "return_to URL invalid against trust_root: scheme"
        unless $rt->scheme eq $tr->scheme;

    # Check the host
    my $trh = $tr->host;
    if($trh =~ s/^\*\.//) { # wildcard trust root
        return 0, "return_to URL invalid against trust_root: wchost"
            unless ($rt->host =~ /\w*\.?$trh/ and $rt->port == $tr->port);
    }
    else { # no wildcard
        return 0, "return_to URL invalid against trust_root: host"
            unless $tr->host_port eq $rt->host_port;
    }
    
    # Check the path and query
    my $trp = $tr->path_query;
    return 0, "return_to URL invalid against trust_root: path"
        unless $rt->path_query =~ /^$trp/;

    # success
    return 1, "return_to URL valid against trust_root";
}

=head3 Accessor Methods

=over

=item C<trust_root>

=item C<identity>

=item C<return_to>

=item C<immediate>

=item C<assoc_handle>

=back

=cut

sub trust_root {
    my $self = shift;
    return $self->{trust_root};
}

sub return_to {
    my $self = shift;
    return $self->{return_to};
}

sub identity {
    my $self = shift;
    return $self->{identity};
}

sub immediate {
    my $self = shift;
    return $self->{immediate};
}

sub assoc_handle {
    my $self = shift;
    return $self->{assoc_handle};
}

package Net::OpenID::JanRain::Server::Response;

use strict;
use warnings;

use Net::OpenID::JanRain::Util qw( hashToKV );

use constant {
    OPENID_PREFIX  =>  'openid.',
};

use Net::OpenID::JanRain::Util qw( appendArgs );

=head1 Net::OpenID::JanRain::Server::Response

This object is returned by the C<answer> methods of
L</Net::OpenID::JanRain::Server::Request> objects.

=head2 Methods

=cut

sub new {
    my ($caller, $request) = @_;
    
    my $class = ref($caller) || $caller;
    
    my $self = {
        request => $request,
        fields => {},
        };

    bless($self, $class);
}

=head3 whichEncoding

Returns 'url' if the response should be returned in a redirect URL,
and 'kvform' if the response should be returned as a plaintext KV form
response.

=cut

sub whichEncoding {
    my $self = shift;
    if($self->request->mode eq 'checkid_immediate' or $self->request->mode eq 'checkid_setup') {
        return 'url';
    }
    else {
        return 'kvform';
    }
}

=head3 signed

Returns a boolean value indicating whether the response should be signed.

=cut

sub signed {
    my $self = shift;

    return $self->{signed};
}

=head3 encodeToURL

Returns a URL for redirecting the user to send the response.

=cut

sub encodeToURL {
    my $self = shift;
    my $fields = {};
    while (my ($key, $value) = each %{$self->{fields}}) {
        my $gnocchi = OPENID_PREFIX.$key;
        $fields->{$gnocchi} = $value;
    }
    return appendArgs($self->request->return_to, $fields);
}

=head3 encodeToKVForm

Returns a KV form string to put in the body of the HTTP response.

=cut

sub encodeToKVForm {
    my $self = shift;
    return hashToKV($self->fields);
}

=head3 addField

 $response->addField($namespace, $key, $value, $signed);

Adds an OpenID field to the response, possibly in an extension namespace.

=head4 Arguments

=over

=item namespace

The namespace to put the field in.  '' or undef will put the field in the
root openid namespace.

=item key

=item value

=item signed

Whether this field should be signed.  Defaults to true if the response
is to a C<checkid_setup> or C<checkid_immediate> request, and false 
otherwise.

=back

=cut

sub addField {
    my $self = shift;
    my $namespace = shift;
    my $key = shift;
    my $value = shift;
    my $signed = shift;
    $signed = ($self->request->mode eq 'checkid_setup' or $self->request->mode eq 'checkid_immediate') unless defined($signed);

    $key = "$namespace.".$key if $namespace;
    $self->{fields}->{$key} = $value;


    if($signed) {
        $self->{signed} = [] unless defined($self->{signed});
        push @{$self->{signed}}, $key;
    }

}

=head3 addFields

 $response->addFields($namespace, \%fields, $signed);

Much like C<addField>, but takes a hash reference containing a number
key/value pairs.

=cut

sub addFields {
    my $self = shift;
    my $namespace = shift;
    my $fields = shift;
    my $signed = shift;

    while (my ($key, $value) = each %$fields) {
        $self->addField($namespace, $key, $value, $signed);
    }
}

=head3 fields

An accessor method for the fields hash ref.

=cut

sub fields {
    my $self = shift;
    return $self->{fields};
}

=head3 request

Returns the request this response is responding to.

=cut

sub request {
    my $self = shift;
    return $self->{request};
}


package Net::OpenID::JanRain::Server::WebResponse;

use strict;
use warnings;

=head1 Net::OpenID::JanRain::Server::WebResponse

This object is meant to be easily encoded into an HTTP response in your
application.

=head2 Accessor Methods

=over

=item code

The HTTP code to use on your response.

=item headers

A hash reference of headers to put on your response.

=item body

The body of the response.

=back

=cut

sub new {
    my ($caller, $code, $headers, $body) = @_; #XXX optionals

    my $class = ref($caller) || $caller;

    my $self = {
        code    => $code,
        headers => $headers,
        body    => $body,
        };

    bless($self,$class);
}

sub code {
    my $self = shift;
    return $self->{code};
}

sub headers {
    my $self = shift;
    return $self->{headers};
}

sub body {
    my $self = shift;
    return $self->{body};
}

package Net::OpenID::JanRain::Server::ProtocolError;

use strict;
use warnings;
use constant {
    OPENID_PREFIX  =>  'openid.',
};

use Net::OpenID::JanRain::Util qw( appendArgs hashToKV );

=head1 Net::OpenID::JanRain::Server::ProtocolError

Objects of this class are returned by XXX when the consumer sends us an
improper request.  It may be encoded to a web response in the same manner
that a L</Net::OpenID::JanRain::Server::Response> object is encoded.

=cut

sub new {
    my $caller = shift;
    my $query = shift;
    my $text = shift;
    my $class = ref($caller) || $caller;

    my $self = {query => $query};
    if ($text) {
        $self->{text} = $text;
    }
    else {
        warn "Error without text";
    }

    bless($self, $class);
}

=head3 text

Returns a string describing the error.

=cut

sub text {
    my $self = shift;
    return $self->{text};
}

=head3 query

returns the query that led to the error.

=cut

sub query {
    my $self = shift;
    return $self->{query};
}

=head3 hasReturnTo

Do we have a return_to URL to send the error back to the server?
(only relevant when the c<whichEncoding> method returns 'url')

=cut

sub hasReturnTo {
    my $self = shift;
    $self->{query} and return 1 if $self->{query}->{OPENID_PREFIX.'return_to'};
    return 0;
}

=head3 encodeToURL

Generates and returns a URL for redirecting the user to alert the consumer
of the error.

=cut

sub encodeToURL {
    my $self = shift;
    my $return_to = $self->{query}->{OPENID_PREFIX.'return_to'};
    
    unless ($return_to) {
        carp("OpenID ProtocolError has no return_to URL to encode onto");
        return undef;
    }

    return appendArgs($return_to, {'openid.mode'  => "error", 
                                   'openid.error' => $self->{text}});
}

=head3 encodeToKVForm

Generates and returns a KV form string for returning in the body of the
response to the consumer.

=cut

sub encodeToKVForm {
    my $self = shift;

    return hashToKV({mode=>'error', error=>$self->text});
}

=head3 fields

Returns a hash ref of the response fields.

=cut

sub fields {
    my $self = shift;
    return {mode=>'error', error=>$self->text};
}

=head3 whichEncoding

Returns a string, either 'url', or 'kvform', based on how the error
should be encoded for transmission.

=cut

sub whichEncoding {
    my $self = shift;

    return undef unless $self->{query};

    my $mode = $self->{query}->{OPENID_PREFIX.'mode'};
    my $return_to = $self->{query}->{OPENID_PREFIX.'return_to'};

    if(($mode eq 'checkid_setup' or $mode eq 'checkid_immediate') and
        $self->hasReturnTo()) {
        return 'url';
    } else {
        return 'kvform';
    }
}

package Net::OpenID::JanRain::Server::Signatory;

use strict;
use warnings;
use Carp;

use Net::OpenID::JanRain::Util qw( toBase64 );
use Net::OpenID::JanRain::CryptUtil qw( randomString );

my $SECRET_LIFETIME = 14 * 24 * 60 * 60; # seconds in a fortnight

# keys have a bogus server URL in them because the filestore
# really does expect that key to be a URL.  This seems a little
# silly for the server store, since I expect there to be only one
# server URL.
my $_normal_key = 'http://localhost/|normal';
my $_dumb_key = 'http://localhost/|dumb';

=head1 Net::OpenID::JanRain::Server::Signatory

This object signs responses and checks signatures.  One is contained
inside every  C<Net::OpenID::JanRain::Server> object.

If you use the
L</encodeResponse> method of the C<Net::OpenID::JanRain::Server> object,
you won't have to know how this object works.  All the object state is
in the OpenID store.

=cut

sub new {
    my ($caller, $store) = @_;

    my $class = ref($caller) || $caller;

    unless ($store->isa('Net::OpenID::JanRain::Stores')) {
        carp "Need an instance of Net::OpenID::JanRain::Stores";
        return undef;
    }
    
    my $self = {store => $store};
    bless($self, $class);
}

=head3 verify

 $is_valid = $signatory->verify($assoc_handle, $sig, $signed_pairs);

=cut

sub verify {
    my ($self, $assoc_handle, $sig, $signed_pairs) = @_;

    my $assoc = $self->getAssociation($assoc_handle, 1);
    
    return 0 unless ($assoc);
    my $expected_sig = toBase64($assoc->signPairs($signed_pairs));

    return $sig eq $expected_sig;
}

=head3 sign

 $signatory->sign($response);

=cut

sub sign {
    my ($self, $response) = @_;

    my $assoc_handle = $response->request->assoc_handle;

    my $assoc;
    if ($assoc_handle) {
        $assoc = $self->getAssociation($assoc_handle, 0);
        unless ($assoc) {
            # We don't have that association.  Send the invalidate handle
            # message back, and fall back on dumb mode.
            $response->addFields('',{invalidate_handle => $assoc_handle});
            $assoc = $self->createAssociation(1);
        }
    }
    else {
        $assoc = $self->createAssociation(1);
    }
    $response->addFields('', {assoc_handle => $assoc->handle}, 0);
    $assoc->addSignature($response->{fields}, $response->signed); 

    return $response;
}

=head3 createAssociation

 $assoc = $signatory->createAssociation($dumbp);

=cut

sub createAssociation {
    my $self = shift;
    my $dumb = shift;
    
    my $assoc_type = 'HMAC-SHA1';
    my $secret = randomString(20);
    my $uniq = toBase64(randomString(4));
    my $now = time;
    my $handle = "_${assoc_type}_${now}_${uniq}_";
    
    $handle = "_d$handle" if $dumb;
    
    my $assoc = Net::OpenID::JanRain::Association->fromExpiresIn(
        $SECRET_LIFETIME, $handle, $secret, $assoc_type);

    if ($dumb) {
        $self->{store}->storeAssociation($_dumb_key, $assoc);
    }
    else {
        $self->{store}->storeAssociation($_normal_key, $assoc);
    }
    return $assoc;
}

=head3 getAssociation

$assoc = $signatory->getAssociation($assoc_handle, $dumb);

=cut

sub getAssociation {
    my ($self, $assoc_handle, $dumb) = @_;
    
    unless (defined($assoc_handle)) {
        carp("assoc_handle must be defined");
        return undef;
    }

    my $key;
    if ($dumb) {
        $key = $_dumb_key;
    }
    else {
        $key = $_normal_key;
    }
    my $store = $self->{store};
    my $assoc = $store->getAssociation($key, $assoc_handle);
    if (defined($assoc) and $assoc->expiresIn == 0) {
        # oid_log("requested association $assoc_handle is expired");
        $store->removeAssociation($key, $assoc_handle);
        return undef;
    }
    return $assoc;
}

=head3 invalidate

 $signatory->invalidate($assoc_handle, $dumb);

=cut

sub invalidate {
    my ($self, $assoc_handle, $dumb) = @_;

    if ($dumb) {
        $self->{store}->removeAssociation($_dumb_key, $assoc_handle);
    }
    else {
        $self->{store}->removeAssociation($_normal_key, $assoc_handle);
    }
}

package Net::OpenID::JanRain::Server;

use strict;
use warnings;
use Net::OpenID::JanRain::Util qw( appendArgs hashToKV );
use Carp;

use constant {
    OPENID_PREFIX  =>  'openid.',
};

my $signatoryClass='Net::OpenID::JanRain::Server::Signatory';
my $webResponseClass='Net::OpenID::JanRain::Server::WebResponse';

=head1 Net::OpenID::JanRain::Server

This object handles requests for an OpenID server.

Queries in hash-ref form may be turned into
L</Net::OpenID::JanRain::Server::Request> objects with the
L</decodeRequest> method.

Requests which are not C<checkid> requests may be passed to the
L<handleRequest> method, and a response will be returned.

L</Net::OpenID::JanRain::Server::Response> objects may be transformed
into L</Net::OpenID::JanRain::Server::WebResponse> objects with the
L<endodeResponse> method, which will also sign the responses if necessary.

=head2 Methods

=head3 new

 $server = new Net::OpenID::JanRain::Server($store);

Instantiate this object with an instance of C<Net::OpenID::JanRain::Stores>.

=cut

sub new {
    my ($caller, $store) = @_;
    my $class = ref($caller) || $caller;

    my $signatory = $signatoryClass->new($store);
    unless (defined($signatory)) {
        carp "Failed to instantiate signatory";
        return undef;
    }
    
    my $self = {
###        store     => $store,
        signatory => $signatory
    };

    bless($self, $class);
}

=head3 handleRequest

Call this method on a L</Net::OpenID::JanRain::Server::Request> object
that is not a L</Net::OpenID::JanRain::Server::CheckIDRequest> and 
the appropriate L</Net::OpenID::JanRain::Server::Response> object will
be returned.

=cut

sub handleRequest {
    my ($self, $request) = @_;

    my $mode = $request->mode;
    if ($mode eq 'check_authentication') {
        return $self->openid_check_authentication($request);
    }
    elsif ($mode eq 'associate') {
        return $self->openid_associate($request);
    }
    else {
        warn "No handler for mode $mode";
        return undef;
    }
}

=head3 signatory

An accessor method to get the signatory object used by the server.

=cut

sub signatory {
    my $self = shift;
    return $self->{signatory};
}

sub openid_check_authentication {
    my ($self, $request) = @_;
    return $request->answer($self->{signatory});
}

sub openid_associate {
    my ($self, $request) = @_;
    my $signatory = $self->{signatory};
    my $assoc = $signatory->createAssociation(0);
    return $request->answer($assoc);
}

=head3 decodeRequest

 $response = $server->decodeRequest(\%query);

This method takes a hash ref of an OpenID query and returns an
L</Net::OpenID::JanRain::Server::Request> object.

=cut

sub decodeRequest {
    my ($self, $query) = @_;
    
    return undef unless %$query;

    my $oidp = 'openid.';
    $oidp =~ s/\./\\./; # escape the dang .
    my $myquery = {};
    while(my ($k, $v) = each %$query) {
        $myquery->{$k} = $v if $k =~ /^$oidp/;
    }
    return undef unless %$myquery;

    my $mode = $myquery->{OPENID_PREFIX.'mode'};

    return $errorClass->new($query, "Query is missing mode") unless $mode;

    if($mode eq 'checkid_setup' or $mode eq 'checkid_immediate') {
        return Net::OpenID::JanRain::Server::CheckIDRequest->fromQuery($query);
    }
    elsif($mode eq 'check_authentication') {
        return Net::OpenID::JanRain::Server::CheckAuthRequest->fromQuery($query);
    }
    elsif($mode eq 'associate') {
        return Net::OpenID::JanRain::Server::AssociateRequest->fromQuery($query);
    }
    else {
        return $errorClass->new($query, "Unknown mode $mode");
    }
}

=head3 encodeResponse

 $web_response = $server->encodeResponse($response);

This method takes a L</Net::OpenID::JanRain::Server::Response> object
and returns the appropriate L</Net::OpenID::JanRain::Server::WebResponse>
object.

=cut

sub encodeResponse {
    my ($self, $response) = @_;
    
    my $encode_as = $response->whichEncoding();

    if ($encode_as eq 'kvform') {
        my $wr = $webResponseClass->new(200, {}, $response->encodeToKVForm);
    }
    elsif($encode_as eq 'url') {

        if ($response->signed) {
            unless ($response->fields->{sig}) {
                my $signatory = $self->{signatory};
                $signatory->sign($response);
            }
        }
        my $wr = $webResponseClass->new(302, 
            {Location => $response->encodeToURL}, undef);
    }
}


