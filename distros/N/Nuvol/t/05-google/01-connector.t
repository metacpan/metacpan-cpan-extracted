use strict;

use Test::More;

use Mojo::File 'tempdir';
use Nuvol::Test::Connector ':all';

my $package = 'Nuvol::Connector';
my $service = 'Google';

my %constants = (
  AUTH_URL  => 'https://accounts.google.com/o/oauth2/auth',
  API_URL   => 'https://www.googleapis.com',
  INFO_URL  => '',
  NAME      => 'Nuvol Google Connector',
  TOKEN_URL => 'https://www.googleapis.com/token',
  SERVICE   => 'Google',
);
my %defaults = (
  app_id        => 'my app id',
  app_secret    => 'my app secret',
  redirect_uri  => 'my redirect uri',
  response_type => 'code',
  scope         => '',
);
my %params = (
  app_id        => 'my app id',
  app_secret    => 'my app secret',
  redirect_uri  => 'my redirect uri',
);
my %tokens = (
  access_token  => 'new access token',
  expires_in    => 3600,
  refresh_token => 'new refresh_token',
  scope         => 'new scope',
);

my $connector = build_test_connector $service, \%params;

test_basics $connector,    $service;
test_constants $connector, \%constants;
test_defaults $connector,  \%defaults;
test_config $connector;
is $connector->url, $constants{API_URL}, 'URL to connector';

note 'Open existing config';

ok $connector = $package->new($connector->configfile), 'Re-open from existing config';

test_basics $connector,       $service;
test_authenticate $connector, \%tokens;
test_disconnect $connector;

done_testing();
