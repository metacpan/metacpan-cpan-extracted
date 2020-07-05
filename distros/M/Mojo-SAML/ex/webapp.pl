use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojolicious::Lite;

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Mojo::File 'path';
use Mojo::SAML ':docs';
use Mojo::SAML::IdP;
use Mojo::Util;

=pod

  $ openssl genrsa -out demo.key 2048
  $ openssl req -new -x509 -key demo.key -out demo.cer -days 365

  # webapp.conf
  {
    SAML => {
      key => 'path/to/demo.key',
      cert => 'path/to/demo.cert',
      idp => 'path/to/remote_idp.xml',
      location => 'https://demo.example.com/saml',
      entity_id => 'my-entity-id', # omit to default to location
    }
  }

=cut

my %ns = (
  saml => 'urn:oasis:names:tc:SAML:2.0:assertion',
  samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
);

my $config = app->plugin('Config');
my $login  = sub {
  my $c = shift;
  my $response = $c->saml->response;

  return $c->render(text => "$response", format => 'xml')
    unless $c->saml->response_success;

  my $username = eval { $response->at('samlp|Response > saml|Assertion > saml|Subject > saml|NameID', %ns)->text };

  return $c->render(text => "$response", format => 'xml')
    unless $username;

  $c->session(username => $username);
  $c->redirect_to('/private');
};
my $saml = app->plugin('SAML', {
  handle_login => $login,
});

# modify the metadata if necessary
my $attr_srv = AttributeConsumingService->new(
  index => 0,
  is_default => 1,
  service_names => ['Standard Attribute Service'],
  requested_attributes => [
    RequestedAttribute->new(
      name => 'urn:oid:1.3.6.1.4.1.5923.1.1.1.7',
      name_format => 'uri',
      friendly_name => 'entitlement',
      is_required => 0,
    ),
  ],
);
push @{$saml->sp_metadata->attribute_consuming_services}, $attr_srv;

get '/' => { text => 'Public' };

get '/private' => sub {
  my $c = shift;
  return $c->saml->authn_request
    unless $c->session->{username};
  $c->render(text => 'PRIVATE!');
};

get '/logout' => sub {
  my $c = shift;
  $c->session(expires => 1);
  $c->redirect_to('/');
};

app->start;

