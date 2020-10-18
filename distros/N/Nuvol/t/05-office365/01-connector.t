use strict;

use Test::More;

use Mojo::File 'tempdir';
use Nuvol::Test::Connector ':all';

my $package = 'Nuvol::Connector';
my $service = 'Office365';

my %constants = (
  AUTH_URL  => 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
  API_URL   => 'https://graph.microsoft.com/v1.0',
  INFO_URL  => 'https://graph.microsoft.com/v1.0/me',
  NAME      => 'Nuvol Office 365 Connector',
  TOKEN_URL => 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
  SERVICE   => 'Office365',
);
my %defaults = (
  app_id        => '6bdc6780-1c1c-4f59-83f8-1b931306f556',
  redirect_uri  => 'https://login.microsoftonline.com/common/oauth2/nativeclient',
  response_type => 'code',
  scope         => 'Files.ReadWrite Files.ReadWrite.All User.Read offline_access',
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
