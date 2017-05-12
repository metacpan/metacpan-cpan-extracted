use warnings;
use strict;

package Net::OAuth2::Scheme;
BEGIN {
  $Net::OAuth2::Scheme::VERSION = '0.03';
}
# ABSTRACT: Token scheme definition framework for OAuth 2.0

our $Factory_Class = 'Net::OAuth2::Scheme::Factory';

# some inside_out object support
# ours are a little weird because our object data are
# the option values that live in closures
# so the only thing we put here are the methods
# which can vary wildly depending on context
#
my %methods_hash = (); # class -> methodname -> tag -> closure
my %next_tag = ();
my %free_tags = ();
our $Temp;

sub new {
    # I am still not convinced there will ever be subclasses;
    # makes much more sense to subclass or replace the factory;
    # but now that I've said that, someone will find an excuse,
    # so we'll just follow the paradigm anyway...
    my $class = shift;

    my $factory_class;
    if ($_[0] eq 'factory') {
        (undef, $factory_class) = splice(@_,0,2); # shift shift
        # Yes, this means (factory => classname) has to be first.
        # Cope.
    }
    else {
        $factory_class = $Factory_Class;
    }
    eval "require $factory_class" or die $@;
    my $factory = $factory_class->new(@_);

    # start the cascade of methods being implemented
    $factory->uses('root');

    # build the object, make sure the method definitions are there
    my $tag =
      pop @{$free_tags{$class} ||= []}
      || ($next_tag{$class} ||= 'a')++;
    for my $method ($factory->all_exports) {
        unless ($methods_hash{$class}{$method}) {
            # mom, dad, don't touch it, it's EVIL
            # but we stay completely strict... hahahahahaha
            eval <<END ;
package ${class};
my \%${method} = ();
sub ${method} {
    my \$self = shift;
    return \$${method}\{\$\$self}->(\@_);
}
\$@{[ __PACKAGE__ . '::Temp']} = \\\%${method};
END
            $methods_hash{$class}{$method} = $Temp;
            undef $Temp;
        }
        $methods_hash{$class}{$method}{$tag} = $factory->uses($method);
    }
    return bless \ $tag, $class;
}

sub DESTROY {
    my $self = shift;
    my $class = ref($self);
    for my $hash (values %{$methods_hash{$class}}) {
        delete $hash->{$$self};
    }
    push @{$free_tags{$class}}, $$self;
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme - Token scheme definition framework for OAuth 2.0

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Exactly how the code would look depends on the respective server
frameworks in use and we're trying to be agnostic about that, but...

  our %access_options = (
    transport => 'bearer',
    format => 'bearer_handle',
    vtable => 'shared_cache',
    cache => Cache::Memcached->new(
      # parameters for resource/authserver shared cache
      ...
    ),
    # see Net::OAuth2::Scheme::Factory for other possibilities
  );

  ##
  ## Within the Client Implementation
  ##

  our $access_scheme = Net::OAuth2::Scheme->new
    (%access_options, context => 'client');

  ... obtain authorization grant
  ... send token request

  # receive token
  #
  my %params = ... decode from JSON, URI fragment, etc...
  my ($error, @token) = $access_scheme->token_accept(%params)
  ... complain if $error

  # use token
  #
  my $request = HTTP::Request->new
     (GET => 'http://resource.example.com?resource=...&api=...&stuff=...');
  ($error, $request) = $access_scheme->http_insert($request, @token);
  ... complain if $error
  ... send $request

  ##
  ## Within the Authorization Server Implementation
  ##

  our $access_scheme =
    Net::OAuth2::Scheme->new
     (%access_options, context => 'auth_server');

  our $refresh_scheme =
    Net::OAuth2::Scheme->new
     (usage => 'refresh', ... options ... );

  # create tokens
  #
  ($error, my @token) =
    $access_scheme->token_create($now=time(), 900, ...);
    ... complain if $error

  ($error, my $refresh) =
    $refresh_scheme->token_create($now, 86400, ...);
    ... complain if $error
  }

  # issue tokens
  #
  ...respond( access_token => @token, refresh_token => $refresh );

  ##
  ## Within the Resource Server Implementation
  ##

  our $access_scheme = Net::OAuth2::Scheme->new
    (%access_options, context => 'resource_server');

  HANDLER for resource endpoint = sub {
     my $psgi_env = ... get PSGI env via whatever means

     # extract tokens from request
     #
     my ($error, @tokens_found) = $access_scheme->psgi_extract($psgi_env);
     ... complain if $error
     ... deal with (@tokens_found != 1) as appropriate
     my @token = @{$tokens_found[0]};

     # validate token
     #
     my ($error, $issue_time, $expires_in, @bindings) =
       $access_scheme->token_validate(@token);

     ... check $error
     ... check $issue_time + $expires_in vs. time()
     ... check @bindings
     ... perform API actions
  }

If one is using an "authorization server push"-style vtable,
the code for that will also need to include something like

  %access_options = (... vtable => 'authserv_push' ...)

  ##
  ## within the Authorization Server implementation
  ##

  our $access_scheme =
    Net::OAuth2::Scheme->new
     (%access_options,
      context => 'auth_server',
      vtable_push => \&my_vtable_push,
     );

  sub my_vtable_push {
    my @new_entry = @_
    ... send serialization of @new_entry to authserv_push endpoint
    return ($error) if ... something bad happened
    return ()
  }

  ##
  ## within the Resource Server implementation
  ##

  our $access_scheme =
    Net::OAuth2::Scheme->new
     (%access_options, context => 'resource_server');

  HANDLER for authserv_push endpoint... = sub {
    ... authenticate authorization server
    my @new_entry = ... unserialize from request;
    my ($error) = $access_scheme->vtable_pushed(@new_entry);
    ... return error response if $error
    ... return success
  }

and if one is using an "resource server pull"-style vtable,
the code for that will need to include something like

  %access_options = (... vtable => 'resource_pull' ...)

  ##
  ## within the Authorization Server implementation
  ##

  our $access_scheme =
    Net::OAuth2::Scheme->new
     (%access_options, context => 'auth_server');

  HANDLER for resource_pull endpoint ... = sub {
    ... authenticate resource server
    my @pull_query = ... unserialize from request
    my @pull_response = $access_scheme->vtable_dump(@pull_query);
    ... return response with serialization of @pull_response
  }

  ##
  ## within the Resource Server implementation
  ##

  our $access_scheme =
    Net::OAuth2::Scheme->new
     (%access_options,
      context => 'resource_server',
      vtable_pull => \&my_vtable_pull,
     );

  sub my_vtable_pull {
    my @pull_query = @_;
    ... send serialization of @pull_query to resource_pull endpoint
    my @pull_response = ... unserialize from response
    return @pull_response;
  }

=head1 DESCRIPTION

A token scheme is a set of specifications for some or all of the following

=over

=item *

token transport method (http headers vs. body or URI parameters)

=item *

token format/encoding (handle vs. assertion vs. something else)
including specification of how much of the binding information is
included with the token vs. sent out of band to the resource server
directly

=item *

communication model ("validator table" a.k.a. "vtable") for sharing
token validation secrets and out-of-band binding information between
the authorization server and the resource server

=item *

ID/key generation for the vtable,

=back

as specialized for

=over

=item *

usage (i.e., access token vs. refresh token vs. authorization code)

=item *

resource (i.e., a resource endpoint or family thereof that will be honoring
the tokens produced by this scheme)

=item *

client profile/deployment (i.e., if there are distinct groups of
clients using the same resource that require different styles of token
for whatever reason), and

=item *

implementation context (client vs. authorization server vs. resource server)

=back

The methods on the scheme object are primarily the methods for producing and
handling tokens in the various stages of the token lifecycle, i.e.,

=over

=item *

an authorization server calls B<token_create> to issue the token and send validation information to the resource server(s) as needed

=item *

a client applies B<token_accept> to the received token to determine (to
the extent possible) whether it is of the expected scheme and then
save whatever needs to be saved for later use

=item *

a client uses B<http_insert> and the saved token information to insert a
token into a resource API message as authorization,

=item *

a resource server does B<psgi_extract> to obtain whatever tokens were
present, and then B<token_validate> to verify them and obtain their
respective binding information.  These are two separate methods
because (1) handling of multiple apparent tokens in a message will
depend on the resource API and is thus outside the scope of these
modules, and (2) for refresh tokens and authorization codes,
B<psgi_extract> is not actually needed.

=back

but there will sometimes be additional hooks a needed by the
communication model (see discussion of B<vtable_push> and
B<vtable_pull> below).

=head1 CONSTRUCTOR

=head2 new

 $scheme = new(%scheme_options);
 $scheme = new(factory => $factory_class, %scheme_options);

See L<Net::OAuth2::Scheme::Factory>, the default factory class,
for what can be in I<%scheme_options>.

Use the second form if you want to substitute your own $factory_class;
note that if you use this option, it must appear first.

Everything that follows describes the behavior of the methods produced
by the default factory class.

=head1 METHODS

The parameter and return values that are used in common amongst the
various scheme object methods are as follows:

=over

=item I<$issue_time>

time of token issue in seconds UTC since The Epoch (midnight, January 1, 1970)

=item I<$expires_in>

number of seconds after I<$issue_time> that token expires

=item I<@bindings>

an arbitrary sequence of string values that are bound into the token.

For the purposes of this module these values are opaque and up to the
module user.  Doubtless an OAuth2 implementation will almost certainly
be including at least resource_id, client_id, and scope...

=item I<$request_out>

an outgoing request as might be composed by a user agent or
application, in the form of an L<HTTP::Request|HTTP::Request> object
or something with a similar interface.

=item I<$request_in>

an incoming request as received by a server URI handler,
in the form of a L<PSGI> environment hash

(see L<HTTP::Message::PSGI> for converting HTTP::Request objects to
PSGI environments, and the various L<Plack::Handler::*|Plack> modules
for how to obtain PSGI environments from other kinds of server request
objects, e.g., Apache(2)::Request, CGI, etc...)

=item I<@token_as_issued>

the token string (C<access_token> value from a token response)
followed by the sequence of alternating keyword-value pairs that
comprise the token as initially sent by the authorization server to
the client.

The keywords used here may include C<token_type> and any
extension parameters registered for use in OAuth2 token responses.
In general the full list represents what is needed in order
to construct an access request.
All values are as they appear in a successful token or authorization
endpoint response (i.e., prior to being encoded into a JSON structure
or URI fragment on the authorization server, or, equivalently, after
such decoding on the client side).

The keywords C<expires_in>, C<scope>, C<refresh_token>, and C<access_token>
are I<never> included.

For refresh tokens and authorization codes, I<@token_as_issued> will
always be a one-element list consisting of a single string value
(i.e., the C<refresh_token> parameter from a token response or the
C<code> parameter from an authorization response)

=item I<@non_token_params>

the keyword-value pairs corresponding to the C<expires_in>, C<scope>,
C<refresh_token> and any other parameters (e.g.,extension, local
variation, etc...) received in a token response that are I<not> needed
in order to construct an access request using this token.

=item I<@token_as_saved>

the token string plus alternating keyword-value pairs in the form that
the token is to be saved on the client.

This may include additional client-side data as required by the token
scheme (e.g., http_hmac requires the receive time).  At the discretion
of the client implementer, some or all of I<@non_token_params> can
also be included as well.

=item I<@token_as_used>

the token string plus alternating keyword-value pairs in the form that
the token gets sent to the resource server.  Here, the I<keyword>s
will generally refer to additional Authorization header attributes,
body parameters, or URI parameters (or something else if anyone comes
up with some other place to stash tokens in an HTTP request) required
by the transport scheme in use; these keywords need not have anything
to do with the keywords that appear in I<@token_as_issued> or
I<@token_as_saved>.

For refresh tokens and authorization codes, I<@token_as_issued> and
I<@token_as_used> are one-element lists consisting of a single string
value.

=item I<$error>

in return values will be C<undef> when the method call succeeds,
and otherwise will be some true string value indicating what went wrong
when the method call fails.

=back

The following methods will be defined on token scheme objects,
depending on the usage and implementation context chosen:

=head2 token_create  I<[Authorization Server]>

 ($error, @token_as_issued) =
   scheme->token_create($issue_time, $expires_in, @bindings)

creates a new token in the form to be sent to the client.  As a side
effect this also communicates any necessary secrets and perhaps also
some subset of the expiration and binding information to the resource
server as needed.

Questions of token format, whether (and which) bindings are physically
included with the token as sent to the client vs. communicated
separately to the resource server, and how such communication takes
place are determined by the format and vtable specifications chosen
for this token scheme.

=head2 token_accept  I<[Client]>

 ($error, @token_as_saved)
   = scheme->token_accept(@token_as_issued, @non_token_params)

=over

=item *

checks that the C<token_type> parameter is as expected for
this token scheme.

=item *

includes in I<@token_as_saved>, additional client-side information (e.g.,
the time of receipt for C<http_hmac> tokens) that may be needed to
construct access requests,

=item *

includes some or all of I<@non_token_params> as determined by the
option settings C<accept_keep> and C<accept_remove>.  Note that the
I<@non_token_params> supplied to this call can be a (possibly empty)
subset of the originally received I<@non_token_params> (i.e., it's
okay to remove these parameters beforehand if you want).

=back

Clients I<can> simultaneously accomodate multiple token transport schemes
provided either each expected C<token_type> value corresponds to at most one
specified token scheme, e.g.,

  my ($error, $use_scheme, @token_as_saved);
  for my $scheme ($bearer_scheme, $http_hmac_scheme, $whatever...) {
     ($error, @token_as_saved)
       = $scheme->token_accept(@token_as_issued);
     unless ($error) {
         $use_scheme = $scheme;
         last;
     }
  }
  unless ($use_scheme) { ... complain... }

or you have some other means of identifying received tokens (e.g.,
some other local-extension URI parameter documented by the
authorization server people tells you which it is)

=head2 http_insert  I<[Client]>

 ($error, $request_out)
  = $scheme->http_insert($request_out, @token_as_saved)

converts I<@token_as_saved> to I<@token_as_used> E<mdash> silently ignoring any
I<@non_token_params> that might be present E<mdash> then modifies (in-place)
the outgoing request so as to include I<@token_as_used> as authorization,
returning the modified request.  This may either add headers,
post-body parameters, or uri parameters as per the transport specification
for this token scheme.

=head2 psgi_extract  I<[Resource Server]>

 ($error, [@token_as_used],...) = $scheme->psgi_extract($request_in)

extracts I<all> apparent tokens present in an incoming request that
conform to this token scheme's transport specification.

Ideally, there would be at most one valid token in any given request,
however, other headers or parameters may, depending on how the
resource API is structured, spuriously match the token transport
specification and we won't find this out until we attempt to validate
the resulting "tokens" (not that this should happen with a
well-designed API, but there may be legacies and compromises to
contend with...)

It may also be that one may wish for a given resource API to accept
multiple tokens in certain situations.  If you go this route, it is
B<strongly recommended> that there be a fixed, small limit on number
of tokens that may be included in any request E<mdash> otherwise you
risk providing an attacker an easy means of brute-force search to
forge/discover token values.

=head2 token_validate  I<[Resource Server, Refresh Tokens and Authcodes]>

 ($error, $issue_time, $expires_in, @bindings)
   = $scheme->token_validate(@token_as_used);

Decodes the token, retrieves expiration and binding information, and
verifies any signature/hmac-values that may be included in the token
format.

The caller is responsible for deciding whether/how to observe the
expiration time and for checking correctness of binding values.

=head2 vtable_pushed  I<[Resource Server]>

 ($error) = $scheme->vtable_pushed(@push_entry)

For use by resource server C<authserv_push> handlers (see ...).

Here I<@push_entry> is an opaque sequence of strings extracted from
the C<authserv_push> message constructed and sent by B<vtable_push>.

=head2 vtable_dump  I<[Authorization Server]>

 @pull_response = $access_scheme->vtable_dump(@pull_query)

For use by authorization server C<resource_pull> handlers (see ...).

Here I<@pull_query> is an opaque sequence of strings extracted from
the pull request constructed and sent by B<vtable_pull> and
I<@pull_response> is the corresponding opaque sequence to be included
in the response and returned from B<vtable_pull> on the resource
server side.  Note that I<@pull_response> may contain an error
indication, but if so, that should be handled by the resource server.

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

