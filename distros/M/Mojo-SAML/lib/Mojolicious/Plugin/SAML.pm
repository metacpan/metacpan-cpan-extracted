package Mojolicious::Plugin::SAML;

use Mojo::Base 'Mojolicious::Plugin';

use Carp ();
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Mojo::File 'path';
use Mojo::SAML ':docs';
use Mojo::SAML::IdP;
use Mojo::URL;
use Mojo::Util;
use Scalar::Util ();

has [qw/metadata route/];

sub sp_metadata {
  my $plugin = shift;
  #TODO this should search for an SPSSODescriptor
  return $plugin->metadata->descriptors->[0];
}

sub register {
  my ($plugin, $app, $conf) = @_;
  $conf ||= {};
  $conf = { %$conf, %{$app->config->{SAML}} };
  Carp::croak 'No SAML configuration given'
    unless keys %$conf;

  my $login = $conf->{handle_login} // Carp::croak 'handle_login is required';
  my $key   = Crypt::OpenSSL::RSA->new_private_key(path($conf->{key})->slurp);
  my $cert  = Crypt::OpenSSL::X509->new_from_string(path($conf->{cert})->slurp);
  my $idp   = Mojo::SAML::IdP->new->from($conf->{idp});

  my $location  = $conf->{location};
  my $entity_id = $conf->{entity_id} // $location;

  my $key_info = KeyInfo->new(cert => $cert);
  my $key_desc = KeyDescriptor->new(
    key_info => $key_info,
    use => 'signing',
  );
  my $post = AssertionConsumerService->new(
    index    => 0,
    binding  => 'HTTP-POST',
    location => $location,
  );
  my $redir = AssertionConsumerService->new(
    index    => 1,
    binding  => 'HTTP-Redirect',
    location => $location,
  );
  my $sp = SPSSODescriptor->new(
    key_descriptors => [$key_desc],
    assertion_consumer_services => [$post, $redir],
    nameid_format => [qw/unspecified/],
  );
  my $metadata = EntityDescriptor->new(
    id => 'MOJOSAML_METADATA',
    entity_id => $entity_id,
    descriptors => [$sp],
    insert_signature => Signature->new(key_info => $key_info),
    insert_xml_declaration => 1,
    sign_with_key => $key,
  );
  $plugin->metadata($metadata);

  $app->helper('saml.authn_request' => sub {
    my ($c, %opt) = @_;

    my $binding = $opt{binding} // 'HTTP-Redirect';
    my $passive = $opt{passive} // 0;
    # TODO get "sign" default from idp
    my $sign    = $opt{sign}    // 1;

    my $url = $idp->location_for(SingleSignOnService => $binding);
    my $req = AuthnRequest->new(
      issuer => $entity_id,
      assertion_consumer_service_index => 0,
      is_passive => $passive,
      nameid_policy => NameIDPolicy->new(format => 'unspecified'),
      destination => "$url",
    );

    if ($binding eq 'HTTP-Redirect') {
      $url->query(SAMLRequest => $req->to_string_deflate);

      if ($sign) {
        $url->query({SigAlg => 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'});
        $key->use_sha256_hash;
        my $val = $url->query->to_string;
        my $sig = $key->sign($val);
        $url->query({Signature => Mojo::Util::b64_encode($sig, '')});
      }

      $c->redirect_to($url);
    } else {
      Carp::croak "Binding '$binding' is not implemented by saml.authn_request helper";
    }
  });

  $app->helper('saml.response' => sub {
    my $c = shift;
    Carp::croak 'saml response methods must be called during a saml response'
      unless my $dom = $c->stash->{'saml.response'};
    return $dom;
  });

  my @ns  = (samlp => 'urn:oasis:names:tc:SAML:2.0:protocol');
  $app->helper('saml.response_success' => sub {
    my $c = shift;
    my $dom = $c->saml->response;
    return !!$dom->at('samlp|Response > samlp|Status > samlp|StatusCode[Value="urn:oasis:names:tc:SAML:2.0:status:Success"]', @ns);
  });

  $app->helper('saml.response_status' => sub {
    my $c = shift;
    my $dom = $c->saml->response;
    return +($dom->at('samlp|Response > samlp|Status > samlp|StatusCode[Value]', @ns) || {})->{Value};
  });

  my $path = Mojo::URL->new($location)->path->to_string;
  my $r = $app->routes->any($path);
  $plugin->route($r);
  Scalar::Util::weaken $plugin->{route};

  $r->get('/descriptor' => sub {
    state $my_meta = $plugin->metadata->to_string; # only render once
    my $c = shift;
    return $c->reply->not_found unless $my_meta;
    $c->render(text => $my_meta, format => 'xml');
  }, 'saml_descriptor');

  $r->get('/authn_request' => sub { shift->saml->authn_request }, 'saml_authn_request');

  $r->any('/' => sub {
    my $c    = shift;
    my $pub  = $idp->public_key_for('signing');
    my $text = Mojo::Util::b64_decode($c->param('SAMLResponse'));
    my $dom  = Mojo::DOM->new->xml(1)->parse($text);
    return $c->reply->exception('Login failed from SAML provider: Response failed to verify')
      unless Mojo::XMLSig::verify($dom, $pub);

    $c->stash->{'saml.response'} = $dom;

    $c->$login;
  }, 'saml_endpoint');

  return $plugin;
}

1;

=head1 NAME

Mojolicious::Plugin::SAML - A simple SAML Service Provider plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

This plugin is an early attempt at making a somewhat turn-key SAML Service Provider (SP) plugin.
It is explicitly for a single SP communicating with a single Identity Provider (IdP).

In the future it is imagined that other more robust plugins might encompass more complex interactions.

=head1 CAVEATS

Nothing about this plugin should be considered stable.
Things can and will change incompatibly until this warning is removed.

=head1 CONFIGURATION

  my $saml = $app->plugin('SAML', \%conf);

The plugin can be configured in two ways.
A hash reference of configuration options can be passed to the plugin loader.
Additionally configuration will be taken from the application's configuration under the C<SAML> toplevel key.

The two sources of configuration will be shallow merged with the application configuration taking precedence.

The following configuration keys are accepted.

=head2 idp

The location of the IdP metadata.
Passed to L<Mojo::SAML::Entity/from>, it can be a url, string containing xml, or file path.

=head2 key

The file path location of an RSA private key.

=head2 cert

The file path location of an X509 certificate generated by the L</key>.

=head2 location

The fully qualified url of the SAML endpoint, including protocol and host.

=head2 entity_id

The name of the SP entity to be created.
Defaults to the value of L</location> if not specified (the common case).

=head2 handle_login

A callback called when a login attempt is made.
This is called after the request is verified.
Note that it does not check L</"saml.response_success">; the callback should and handle accordingly.

=head1 HELPERS

=head2 saml.authn_request

  $c->saml->authn_request(%options);

Generate and render an AuthnRequest based on the following key-value options

=over

=item binding

The binding that should be used for the request.
Defaults to C<HTTP-Redirect>.

Currently no other bindings are supported, however that is planned.

=item passive

Boolean indicating if the request should be passive.
Defaults to false.

A passive request checks to see if the subject is already logged in.
The user is not prompted to login and they aren't shown interactive pages though they may be redirected.
The response is as usual for a login attempt, though on failure, the response is not successful (see L</"saml.response_success"> and L</"saml.response_status">).

=item sign

Boolean indicating if the request should be signed.
Defaults to true (though it should and probably will default to the IdP's preference).

=back

=head2 saml.response

  my $dom = $c->saml->response;

Returns the parsed (and validated) SAML response (as a L<Mojo:DOM> object).
This must only be called during the response to a SAML interaction, notably during L</handle_login>.

=head2 saml.response_success

  my $bool = $c->saml->response_success;

Returns a boolean indicating if the SAML response was succesful.
This must only be called during the response to a SAML interaction, notably during L</handle_login>.

=head2 saml.response_status

  my $status = $c->saml->response_status;

Returns the string status from the SAML response.
This may be useful if L</"saml.response_success"> was false in order to differentiate the cause of the failure.
This must only be called during the response to a SAML interaction, notably during L</handle_login>.

=head1 ROUTES

This plugin creates several routes all existing under the base url derived from L</location>.
They are described below by name and path, where the base path is assumed to be C</saml>.

=head2 saml_endpoint

  /saml

This is the primary interaction point for the IdP service.

=head2 saml_descriptor

  /saml/descriptor

This url renders the Entity Metadata for the service, containing the SP descriptor that the IdP will need for configuration.

=head2 saml_authn_request

  /saml/authn_request

This url generates an AuthnRequest to the IdP via L</"saml.authn_request"> helper called without options (ie, using the default options).

=head1 ATTRIBUTES

The plugin implements the following attributes.

=head2 metadata

  my $doc = $saml->metadata;

Stores the generated metadata, an instance of L<Mojo::SAML::Document::EntityDescriptor>.
This can be modified before the first time is is served by L</saml_descriptor>.
This is especially useful for injecting requested attributes.

Currently the plugin is designed to generate the SP metadata.
Setting the metadata from an XML file is planned but not yet implemented.
Setting this attribute is not recommended.

=head2 route

  my $r = $saml->route;

This holds the L<Mojolicious::Routes::Route> object that is the top-level of the tree of L</ROUTES>.
The reference is weakened when initially stored.

This attribute is intended for interrogating and possibly modifying the route object itself.
Setting this attribute will not be very useful.

=head1 METHODS

=head2 register

  my $saml = $app->plugin('SAML');

The method called when the plugin is loaded by the application.
Returns the plugin instance itself.

Note that this is useful to change definitions before the application has begun serving requests.
Once the application has begun to serve requests, changes to this object or its data are not recommended and the behavior in that case will be undefined.

=head2 sp_metadata

  my $doc = $saml->sp_metadata;

Returns the generated metadata for the SP, an instance of L<Mojo::SAML::Document::SPSSODescriptor>.
This reference is also available from L</metadata> but this is more convenient.

Note that the implementation of this method is still undetermined.
Specifically don't rely on what would happen if you replace this element from the L</metadata>.

