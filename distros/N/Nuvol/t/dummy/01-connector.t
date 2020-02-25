use strict;

use Test::More;

use Mojo::File 'tempdir';
use Nuvol::Test::Connector ':all';

my $package = 'Nuvol::Connector';
my $service = 'Dummy';

my %constants = (
  API_URL   => 'file:',
  AUTH_URL  => 'auth_url',
  INFO_URL  => 'info_url',
  NAME      => 'Nuvol Dummy Connector',
  TOKEN_URL => 'token_url',
  SERVICE   => 'Dummy',
);
my %defaults = (
  app_id        => 'dummy_app_id',
  redirect_uri  => 'redirect_uri',
  response_type => 'code',
  scope         => 'dummy_scope',
);
my %tokens = (
  access_token  => 'new access token',
  expires_in    => 3600,
  refresh_token => 'new refresh_token',
  scope         => 'new scope',
);

my $connector = build_test_connector $service;

test_basics $connector,    $service;
test_constants $connector, \%constants;
test_defaults $connector,  \%defaults;
test_config $connector;
is $connector->url, $constants{API_URL} . $connector->configfile->dirname, 'URL to connector';

note 'Open existing config';

ok $connector = $package->new($connector->configfile), 'Re-open from existing config';

test_basics $connector,       $service;
test_authenticate $connector, \%tokens;
test_disconnect $connector;

done_testing();
