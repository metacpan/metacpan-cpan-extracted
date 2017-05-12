use strict;
use warnings;

package Net::OAuth2::Scheme::Factory;
BEGIN {
  $Net::OAuth2::Scheme::Factory::VERSION = '0.03';
}
# ABSTRACT: the default factory for token schemes

use parent 'Net::OAuth2::Scheme::Option::Builder';

use parent 'Net::OAuth2::Scheme::Mixin::Root';
use parent 'Net::OAuth2::Scheme::Mixin::Transport';
use parent 'Net::OAuth2::Scheme::Mixin::Format';
use parent 'Net::OAuth2::Scheme::Mixin::Accept';
use parent 'Net::OAuth2::Scheme::Mixin::VTable';
use parent 'Net::OAuth2::Scheme::Mixin::NextID';

#... and done!

# If you are trying to figure this out, start with Root

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Factory - the default factory for token schemes

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # The recipes;
  #
  # can be hardcoded, initialized from config files, etc...

  my %recipe_client = (
     context => 'client',
     transport => 'bearer'
     ... or ...
     transport => 'hmac_http',
  )

  # more stuff for authorization servers and resource servers
  my %recipe_common = (
     %recipe_client,
     format => 'bearer_handle', # or 'bearer_signed'
     ... or ...
     format => 'hmac_http',

     vtable => 'shared_cache', # default
     cache => $cache_object    # shared cache for authservers + resources
     ...or...
     vtable => 'authserv_push',
     ...or...
     vtable => 'resource_pull',
  );

  # the completely specialized versions:
  my %recipe_auth = (
     %recipe_common,
     context => 'auth_server',

     # if authserv_push
     vtable_push => \&my_push_method,
  );

  my %recipe_resource = (
     %recipe_common,
     context => 'resource_server',

     # if authserv_push or resource_pull
     cache => $private_cache_object,  # only accessible to resource server

     # if resource_pull
     vtable_pull => \&my_pull_method,
     },
  );

  # for refresh tokens
  my %recipe_refresh = (
     usage => 'refresh',
     format => 'bearer_handle', # or 'bearer_signed'

     vtable => 'shared_cache',
     cache => $private_cache_object,  # only accessible to authserver(s)
  );

  ######
  # client code

  my $access_scheme = Net::OAuth2::Scheme->new(%recipe_client);

  ######
  # authserver code

  my $access_scheme   = Net::OAuth2::Scheme->new(%recipe_auth);
  my $refresh_scheme  = Net::OAuth2::Scheme->new(%recipe_refresh);
  my $authcode_scheme = Net::OAuth2::Scheme->new(%recipe_authcode);

  ######
  # resource code

  my $access_scheme = Net::OAuth2::Scheme->new(%recipe_resource);

=head1 DESCRIPTION

A token scheme factory object parses a collection of option settings
(normally given as the arguments for L<Net::OAuth2::Scheme>->B<new()>),
and then exports a set of specialized methods (closures) that a
corresponding scheme object will need.  The implementation context and
intended usage determine which option values are referenced/needed and
which methods will ultimately be produced.

The factory object is ephemeral and intended to be able to
self-destruct as soon as the exported methods are installed on the
scheme object being created.

One should generally not need to create factory objects directly,
though it I<is> intended for one to be able to design customized
factory I<classes> with their own option group definitions and
implementation methods to, say, accomodate new token formats or
transport schemes.  See
L<Net::OAuth2::Scheme::Option::Builder> and
L<Net::OAuth2::Scheme::Option::Defines> and the various mixins
L<Net::OAuth2::Scheme::Mixin::*> for a sense of how this works
[... since we're still in alpha release here, be aware that this
particular part of our world may be in a bit of flux for a while...]

=head1 KINDS OF OPTIONS

There will generally be two kinds of option settings

=over

=item I<option_name> C<=E<gt>> I<value>

which directly sets the value of the specified option.

=item I<group_name> C<=E<gt>> I<implementation>

which has the effect of setting an entire group of options.
(Options that are members of a group can be set individually,
but in most cases you shouldn't, and if you do, you need to
be sure you set all of them).

I<implementation> is either a string naming the implementation choice
that this group represents or an arrayref whose first element is said
implementation choice and the remaining elements are alternating
keyword-value pairs, e.g.,

  transport => ['bearer',
                 param => 'oauth_second',
                 allow_uri => 1]

which specify the settings of related options that the implementation
directly depends on.  Generally each keyword here will be the name of
some option with some prefix stripped.  E.g., the previous example is
equivalent to specifying

  transport => 'bearer',
  bearer_param => 'oauth_second',
  bearer_allow_uri => 1,

=back

Group settings and single-option settings can be given in any order;
nothing is executed until the context/usage is determined and a scheme
object needs to be produced.

Note, however, that the usual rules for initializing perl hashes still
apply here, e.g., if you specify an option setting twice in the same
parameter list, the first will be silently ignored.

An option setting is regarded as I<constant>, i.e., once an option
value is actually set, it is an error to attempt to set it a different
value later.

You can use the C<defaults> option (or C<defaults_all> if you are
completely crazy) to change the defaults for certain options without
actually setting them (if say, one of the existing defaults turns out
to be stupid, or you are building a scheme template into which Other
People will be inserting Actual Settings later...).

=head1 OPTIONS

Generally you will have to set one of C<usage> or C<context> to
determine how/where the scheme object will be used.

For client implementations, specifying C<transport> should suffice.
Authorization and resource servers will also need specifications for
at least C<format> and C<vtable>.

Specifying option settings often entails the presence of others (e.g.,
once you decide on a C<vtable> implementation, a setting for C<cache>
will be required, at least in all of the current implementations)
which will be noted below.

=head2 Usage and Implementation Context

=over

=item C<usage>

This specifies the intended use of the token, one of the following

=over

=item C<'access'>

(Default.)
An access token for use by a client to make use of a particular API at
a resource server.

=item C<'refresh'>

A refresh token for use by a client at an authorization server's token
endpoint to obtain replacement access tokens.

=item C<'authcode'>

An authorization code for use by a client at an authorization server's
token endpoint to obtain access and refresh tokens.

(Strictly speaking, authorization codes are not regarded as tokens by
the OAuth 2 specification, however they require the same methods as
refresh tokens, i.e., they need to be created and validated.
Currently authcode schemes differ from refresh token schemes only in
choice of binding information, which is outside the scope of these
modules, so C<refresh> and C<authcode> schemes are functionally
identical, for now...)

=back

Note that in OAuth2, client and resource server implementations do
not, in fact, (currently) need to use scheme objects other than
C<< usage => 'access' >> ones.

While client implementations do in fact see refresh tokens and
authorization codes, in that context they are simply passed through as
opaque strings and all questions of transport that would normally be
of interest are already completely determined by the OAuth2 protocol
itself, so there are no actual methods that need to be made available.

=item C<context>

For access-token schemes, this specifies the implementation context,
one or more of the following:

=over

=item C<'client'>

This scheme object is for use in a client implementation.
The methods B<token_accept> and B<http_insert> will be provided.

=item C<'resource_server'>

This scheme object is for use in a resource server implementation.
The methods B<psgi_extract> and B<token_validate> will be provided.

=item C<'auth_server'>

This scheme object is for use in an authorization server
implementation.  The B<token_create> method will be provided.

=back

Here, the option value can either be as single string or a listref
in the case of combined implementations where the same process is
serving multiple roles for whatever reason.

Note that while refresh token and authorization code schemes are only
needed within an authorization server implementation, since the same
server also has to be able to I<receive> these tokens/codes, the
resource-side methods need to be enabled.  Thus the scheme object is
produced (mostly) as if

 context => [qw(auth_server, resource_server)]

were specified, meaning that any option settings that would otherwise
only be necessary for a resource server implementation will be
required in these cases as well.

=back

=head2 Transport Options

The transport options determines how B<psgi_extract> and
B<http_insert> are implemented.  They concern where the token appears
in a given HTTP message, the usual choices being a header field, a
(POST or other) body parameter, or a URI parameter.  In the event that
a header field is used, the header in question will generally be
"authorization-formatted", i.e., formatted as per L<rfc2617|http://datatracker.ietf.org/doc/rfc2617/> and
successor specifications, in which case an authorization scheme name
will also need to be specified.

=over

=item C<transport>

The specific transport scheme to use; current available choices are:

=over

=item C<'bearer'>

Bearer token (L<draft-ietf-oauth-v2-bearer|http://datatracker.ietf.org/doc/draft-ietf-oauth-v2-bearer/>) consisting of a single
(secret, unpredictable) string.
The various C<bearer_> options below apply and

=item C<'http_hmac'>

HTTP-HMAC token (L<draft-ietf-oauth-v2-http-mac|http://datatracker.ietf.org/doc/draft-ietf-oauth-v2-http-mac/>),
a "proof-style" token in which the token is a string (key identifier)
and two additional parameters (C<nonce>, C<mac>) placed in an Authorization
header constituting proof that the client possesses the token secret
without having to actually send the secret.
The various C<http_hmac_> options below apply.

=back

=back

The following generic transport options are applicable to all choices
of C<transport> implementation.

=over

=item C<transport_header>

if this is a transport scheme that allows the use of headers,
indicates the header to be used by clients and also as the header
where tokens will be recognized by resource servers if
C<transport_header_re> has not been set.

Default is C<"Authorization">.

=item C<transport_header_re>

regexp; if this is a transport scheme that allows the use of headers,
the resource server will recognize tokens in headers whose names match
this pattern.

=item C<transport_auth_scheme>

if this is a transport scheme that calls for an
Authorization-formatted header, indicates the authorization scheme to
be used by clients and also the scheme that will be recognized by
resource servers if C<transport_auth_scheme_re> has not been set.

=item C<transport_auth_scheme_re>

regexp; if this is a transport scheme that calls for an
authorization-formatted header, the resource server will recognize
tokens in headers whose authorization scheme matches this pattern.

=back

The following options apply when C<< transport => 'bearer' >> is
selected and can be included with the C<bearer_> prefix omitted, e.g.,

 transport => ['bearer', allow_body => 1],

=over

=item C<bearer_allow_body>

boolean; if true, (default) resource server will recognize tokens
located in the request body, otherwise, request body will be ignored
when searching for tokens.

=item C<bearer_allow_uri>

boolean; if true, resource server will recognize tokens located in the
request URI, otherwise, (default) request URI will be ignored when
searching for tokens.

=item C<bearer_client_uses_param>

boolean; if true, client send the token as a body or URI parameter
(use whichever is available as per C<bearer_allow_body> or
C<bearer_allow_uri>, preferring body), rather than a header,
otherwise, (default) client will send the token in an
authorization-formatted header.

=item C<bearer_header>

clients place tokens in this (authorization-formatted) header.
This also serves as the default header where resource servers look for
tokens if C<bearer_header_re> is not set.  Default is
C<'Authorization'>.

=item C<bearer_header_re>

regexp; resource server looks for tokens in headers whose names match this

=item C<bearer_param>

name of body or URI parameter for client to use if either C<allow_uri> or C<allow_body> is set and C<bearer_client_uses_param> is set.  This also serves as the default parameter name the resource server looks for if C<bearer_param_re> is not set.  Default is C<'oauth_token'>.

=item C<bearer_param_re>

regexp; if C<allow_uri> or C<allow_body> is set, resource server should look for tokens in parameters with matching names.

=item C<bearer_scheme>

if authorization-formatted headers are called for, client will use this authorization scheme.  This also serves as the default pattern for the scheme that resource servers will recognize if C<bearer_scheme_re> is not set.  Default is C<'Bearer'>.

=item C<bearer_scheme_re>

regexp; resource server recognizes tokens in authorization-formatted headers whose scheme matches this pattern.

=item C<bearer_token_type>

authorization server sets and client should expect this value of C<token_type> in I<@token_as_issued>.  Default is C<'Bearer'>.

=back

The following options apply when C<< transport => 'http_hmac' >> is selected and can be included with the C<http_hmac_> prefix omitted (e.g., C<< transport => ['http_hmac', header => 'X-HTTP-HMAC'] >>):

=over

=item C<http_hmac_header>

clients place tokens in this header field.  This also serves as the default header where resource servers look for tokens if C<http_hmac_header_re> is not set.  Default is C<'Authorization'>.

=item C<http_hmac_header_re>

regexp; resource server looks for tokens in headers whose names match this pattern.

=item C<http_hmac_scheme>

client will use this authorization scheme.  This also serves as the default pattern for the scheme that resource servers will recognize if C<http_hmac_scheme_re> is not set.  Default is C<'MAC'>.

=item C<http_hmac_scheme_re>

regexp; resource server will recognize tokens in authorization-formatted headers whose scheme matches this pattern.

=item C<http_hmac_nonce_length>

length of nonce that clients should generate

=item C<http_hmac_token_type>

authorization server sets and client should expect this value of C<token_type> in I<@token_as_issued>.  Default is C<'mac'>.

=back

=head2 Acceptance Options

The following options customize the behavior of B<token_accept>:

=over

=item C<accept_keep>

listref of keywords or C<'everything'>; indicating which values should be included in I<@token_as_saved>.  C<'everything'> indicates that all available keywords should be included except for those specified in C<accept_remove>.  Default is C<'everything'>

=item C<accept_remove>

listref of keywords; indicates which values B<token_accept> should exclude from I<@token_as_saved> in the case where C<accept_keep> is indicating that everything should be kept by default; this option is ignored, otherwise.  Default is C<< ['expires_in', 'scope', 'refresh_token'] >>

=back

=head2 Format Options

The following options determine the format/encoding of a token and the binding information that it includes, if there is a choice about this.

=over

=item C<format>

This is an option group, providing C<token_create>, C<token_parse>, and C<token_finish>.
Choices are

=over

=item C<'bearer_handle'>

Use a "handle-style" bearer token where the token string is a random
base64url string with no actual content.  Expiration information and
all binding values must live in the vtable and need to be communicated
out of band to the resource server.  Implies C<< v_id => 'random' >>.

=item C<'bearer_signed'>

Use a "assertion-style" bearer token where the token string includes
some or all of the binding values, a nonce, and a hash value keyed on
a shared secret that effectively signs everything.  Only the shared
secret and remaining binding values needs to be kept in the vtable and
communicated out of band to the resource server.

=item C<'hmac_http'>

Implements the formatting portion of
L<draft-ietf-oauth-v2-http-mac|http://datatracker.ietf.org/doc/draft-ietf-oauth-v2-http-mac/>
(see description under C<transport_hmac_http>).  Expiration
information and all binding data live in the vtable and must be
communicated out of band to the resource server, as for
C<'bearer_handle'> formatted tokens.

=back

=back

The following options apply when C<< format => bearer_signed >> is
selected and can be included with the C<bearer_signed_> prefix omitted
(e.g., C<< transport => ['bearer_signed', hmac => 'hmac_sha256'] >>).

=over

=item C<(bearer_signed_)hmac>

HMAC algorithm to use for signing tokens.  Default is C<'hmac_sha224'>.

=item C<(bearer_signed_)nonce_length>

integer; length (bytes) of random nonce/salt material to be included
in the token.  Default is half of the keylength of the chosen HMAC
algorithm.

=item C<(bearer_signed_)fixed>

listref; initial sequence of bound values that must always be the same
(and are thus never included with the token).  Setting this to a
nonempty list causes B<token_create> to fail when I<@bindings> does
not begin with these values in the specified order, and causes
B<token_validate> to always return a I<@bindings> list beginning with
these values.  Default is an empty list.

=back

The following options apply when C<< format => http_hmac >> is
selected and can be included with the C<http_hmac_> prefix omitted
(e.g., C<< transport => ['http_hmac', hmac => 'hmac_sha256'] >>).

=over

=item C<http_hmac_hmac>  (format/http_hmac)

The HMAC algorithm to be used.

=back

=head2 Validator Table (vtable) Options

The validator table or "vtable" is the mechanism via which secrets are
communicated from the authorization server to the resource server.

Conceptually, it is a shared cache, for which two functions are
exposed to the formatting group: C<vtable_insert>, which the
authorization server uses to write new secrets and binding values to
the cache, and C<vtable_lookup>, which the resource server uses to
obtain these values as needed to validate a given token and return the
bindings and expiration data associated with it.

=over

=item C<vtable>

Determines which vtable implementation paradigm to use, one of:

=over

=item C<'shared_cache'>

The cache is an actual (secure) shared cache, accessible to both the
authorization server and the resource server, whether this be, say,

=over

=item *

a L<memcached|http://search.cpan.org/search?query=memcached&mode=all>
server (or a farm thereof) mutually accessible to
authorization and resource servers, which can then live on entirely
different hosts or even distinct network sites

=item *

a file-based cache (e.g., L<Cache::File>), which requires
authorization and resource servers to either be on the same host
or have access to the same file server

=item *

a shared-memory-segment cache (e.g., L<Cache::Memory>), which requires
authorization and resource servers to either be on the same host.

=item *

some kind of shared internal reference in the case where the
authorization and resource requests are handled by the same process.

=back

C<vtable_insert> and C<vtable_lookup> translate directly to
C<vtable_put> and C<vtable_get> (see C<vtable-cache> below) with no
additional machinery.  Secrets inserted by the authorization server
just become automatically available immediately on the resource
server, and we don't have to know exactly how the communication
happens because the cache implementer already took care of that for
us.

=item C<'authserv_push'>

There is a cache, but it is local/private to the resource server.

C<vtable_insert> by the authorization server is actually
B<vtable_push> which sends the new entry to the resource server by
some means.  A push-handler in the resource server receives the entry
and calls B<vtable_pushed> to insert it into the actual cache, and
either B<token_create> blocks until the push response is received or
(if you care about speed and can tolerate the occasional race condition
failure) we just assume the resource server has enough of a head start
that the insertion will be completed by the time the client gets
around to actually using the token.

C<vtable_lookup> by the resource server is then just C<vtable_get>.

The function B<vtable_push> must be supplied in the authorization
server implementation.  There must also be a resource server push
endpoint with a handler that calls the the scheme object's
B<vtable_pushed> method on whatever (opaque list) value receives,
sending back as a response whatever return value (null or error code)
it gets.

=item C<'resource_pull'>

There is a cache, but it is (again) local/private to the resource server.

C<vtable_insert> by the authorization server does C<vtable_enqueue>,
which just places the entry on an internal queue.

C<vtable_lookup>, when called by the resource server, does the following

=over

=item *

a call to C<vtable_get>, which may succeed or fail.
Failure is immediately followed by

=item *

a call to C<vtable_pull> which is expected to send a query to the authorization
server.

=item *

A pull handler on the authorization server then calls C<vtable_dump>
to flush the contents of the internal queue and
incorporate this list value into a response back to the resource server.

=item *

C<vtable_pull> then receives that response, extracts the reply list value
and returns it, at which point

=item *

C<vtable_load> can then load the new entries into the resource
server's cache and then

=item *

C<vtable_get> can be retried.

=back

The function B<vtable_pull> must be supplied.

The function B<vtable_dump> is available on the scheme object to the
authorization server implementation.  Its argument is expected to be
the query value received by the pull-handler, and its return value
is to be included in the response to the pull request.

=back

=item C<vtable_pull>

coderef; implementation for B<vtable_pull>
as used/required by C<< vtable => resource_pull >> in a resource
server implementation.  It takes an arbitrary opaque list of arguments,
sends them to the authorization server's resource_pull endpoint,
collects the (opaque list) response it receives and returns it,
or returns a one-element error-code list if the send fails.

=item C<vtable_push>

coderef; implementation for B<vtable_push>
as used/required by C<< vtable => authserv_push >> in an
authorization server implementation.
It takes an arbitrary opaque list of arguments,
sends them to the resource server's authserv_push endpoint,
collects the success or error-code response that it receives,
and returns null or the error code accordingly.

=item C<vtable_cache>

The low-level cache interface; provides C<vtable_get> and C<vtable_put> methods.
The default implementation is

=over

=item C<'object'>

which requires C<cache> to be set as described below.

=back

I<< (...some day there may also be a straight hash-reference
implementation for those cases where response and authorization server
are the same process and somebody wants to be ultra-secure by not even
allowing the cache into shared memory... but I'm not going to worry
about this for now...) >>

=item C<vtable_pull_queue>

Determines how the queue for C<< vtable => resource_pull >>, is implemented.
(implementation is a matter of supplying four functions
C<vtable_enqueue>, C<vtable_dump>, C<vtable_query>, and C<vtable_load>).

Current choices are

=over

=item C<'default'>

=back

=back

=head2 Current Secret Options

For C<< format => bearer_signed >> (and possibly other uses later),
there is a shared secret that needs to be communicated out of band to the resource server and that needs to be expired and regenerated every so often.  Generally, there will be two secrets active at any given time (since after regeneration, we keep the old one around and continue to honor tokens generated from it until it expires).

=over

=item C<current_secret_length>

integer; number of bytes in the share secret

=item C<current_secret_rekey_interval>

integer; number of seconds before expiration that the current secret gets regenerated.

=item C<current_secret_lifetime>

integer (default is twice C<current_secret_rekey_interval>); secrets are to expire this many seconds after being regenerated.

=back

=head2 Cache Options

The following options apply when C<< vtable_cache => object >> is chosen

=over

=item C<cache>

The actual cache object to use, some object that implements the L<Cache|Cache> interface, specifically C<get()> and the 3-argument C<set()>.

=item C<cache_grace>

integer; setting this causes actual expiration times for items in the cache to be set this many seconds beyond the stated expiration time, i.e., so that the cache retains expired entries this much longer.  This also similarly extends the time that items are kept in the queue for C<< vtable_pull_queue => default >>.

=item C<cache_prefix>

a string that is prefixed to all vtable cache keys.  If you are using this same cache for other purposes than holding vtable entries, make sure that said other purposes use different prefixes or at least that I<this> prefix is chosen so that no vtable entry will be confused with an entry made for some other purpose.  Default is C<"vtab:">.

=back

=head2 Vtable ID Generation Options

The following options govern the generation of keys for vtable entries.

=over

=item C<v_id>

one of

=over

=item C<'counter'>

=item C<< ['counter', I<tag> ] >>

generate sequential IDs using a counter.
Providing I<tag> sets C<counter_tag> (which see).

=item C<'random'>

=item C<< ['random', I<n> ] >>

generate random IDs using the random number generator.  Providing I<n>
sets C<v_id_random_length>, which needs to be large enough so as to
make collisions between random IDs as unlikely as feasible over the
lifetime of the tokens produced by this scheme.

=back

The default is C<'counter'> unless the scheme is one (e.g.,
C<'bearer_handle'>) that explicitly requires unpredictable IDs.

Note that random IDs currently begin with a 0-127 byte while counter
IDs begin with a 128-255 byte, so no random ID should ever collide
with a counter ID.  Likewise, counter IDs generated from the same
C<counter_tag> are guaranteed not to collide.

=item C<v_id_random_length>

integer; for when C<< v_id => 'random' >>, the number of random bytes
to use when creating the ID (must be at least 8).  Note that the ID
ultimately created will generally be longer than this, both due to the
possible inclusion of C<v_id_suffix> and any encoding (e.g.,
base64url) that may be needed.

=item C<counter_tag>

(default C<''>) for when C<< v_id => 'counter' >>, a string tag identifying
which counter to use.  A fresh counter will be initialized if the
specified tag has not been seen before.

=item C<v_id_suffix>

(default C<''>) is added to the end of every ID generated in this
scheme.  The main use of this is to distinguish (and thus prevent
collisions between) IDs generated by multiple hosts in the situation
where there are multiple authorization servers issuing tokens for the
same resource.

=back

Note that the counter associated with a given tag is guaranteed to
produce distinct IDs on each invocation during an arbitrary 194-day
(2^24 second) window around the time of invocation, regardless of
which process or thread/PerlInterpreter it is invoked from.

Therefore all schemes using the same cache object with the same
C<cache_tag> and the same C<v_id_suffix> should be sure to use the
same counter tag in order not to have ID collisions
when C<< v_id => 'counter' >>

(For C<< v_id => 'random' >>, one has to rely that the ID is
sufficiently long to make collisions extremely unlikely.)

=head2 Random Number Generator Options

The random number generator is used for generation of vtable IDs,
nonces, secrets, and other unpredictable artifacts that need to be
created.

=over

=item C<random_class>

package name; currently C<'L<Math::Random::ISAAC>'>
and C<'L<Math::Random::MT::Auto>'> (Mersenne Twister) are supported.

=item C<random>

coderef; takes an integer and returns a string of that many random bytes

=back

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

