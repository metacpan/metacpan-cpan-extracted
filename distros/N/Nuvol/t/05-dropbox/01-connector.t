use strict;

use Test::More;

use Mojo::File 'tempdir';
use Nuvol::Test::Connector ':all';

my $package = 'Nuvol::Connector';
my $service = 'Dropbox';

my %constants = (
  AUTH_URL  => 'https://www.dropbox.com/oauth2/authorize',
  API_URL   => 'https://api.dropboxapi.com/2',
  INFO_URL  => 'https://api.dropboxapi.com/2/check/user',
  NAME      => 'Nuvol Dropbox Connector',
  TOKEN_URL => 'https://api.dropboxapi.com/oauth2/token',
  SERVICE   => 'Dropbox',
);
my %defaults = (
  app_id        => 'g536fryrx8oyijl',
  redirect_uri  => 'https://nuvol.ch/redirect',
  response_type => 'token',
  scope         => 'none',
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
is $connector->url, $constants{API_URL}, 'URL to connector';

note 'Open existing config';

ok $connector = $package->new($connector->configfile), 'Re-open from existing config';

test_basics $connector,       $service;
test_authenticate $connector, \%tokens;
test_disconnect $connector;

done_testing();
