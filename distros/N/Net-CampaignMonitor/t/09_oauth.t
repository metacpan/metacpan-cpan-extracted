#!/usr/bin/perl

use strict;
use Test::More;
use Test::Exception;
use Params::Util qw{_STRING};

if ( Params::Util::_STRING($ENV{'CAMPAIGN_MONITOR_ACCESS_TOKEN'}) &&
     Params::Util::_STRING($ENV{'CAMPAIGN_MONITOR_REFRESH_TOKEN'}) ) {

  my $access_token = $ENV{'CAMPAIGN_MONITOR_ACCESS_TOKEN'};
  my $refresh_token = $ENV{'CAMPAIGN_MONITOR_REFRESH_TOKEN'};

  plan tests => 16;

  use_ok('Net::CampaignMonitor');

  my $cm = Net::CampaignMonitor->new(
    secure  => 1,
    access_token => $access_token,
    refresh_token => $refresh_token,
  );

  isa_ok($cm, 'Net::CampaignMonitor');

  my $refresh_token_result = $cm->refresh_token();

  ok(Params::Util::_STRING($refresh_token_result->{access_token}), 'New access token');
  ok(Params::Util::_POSINT($refresh_token_result->{expires_in}), 'New expires in value');
  ok(Params::Util::_STRING($refresh_token_result->{refresh_token}), 'New refresh token');

  my $results = $cm->account_countries();

  ok(Params::Util::_POSINT($results->{code}), 'Countries call using OAuth result code');
  ok($results->{code} eq '200', 'Countries call using OAuth result code of 200');
  ok(Params::Util::_HASH($results->{headers}), 'Countries call using OAuth result headers');
  ok(Params::Util::_ARRAY($results->{response}), 'Countries call using OAuth result response');

} else {
	plan tests => 8;
  
	use_ok('Net::CampaignMonitor');
}

# Get authorize_url excluding state
my $authorize_url = Net::CampaignMonitor->authorize_url(
  client_id => 8998879,
  redirect_uri => 'http://example.com/auth',
  scope => 'ViewReports,CreateCampaigns,SendCampaigns'
);

ok(Params::Util::_STRING($authorize_url), '$authorize_url is a string');
ok($authorize_url eq 'https://api.createsend.com/oauth?client_id=8998879&redirect_uri=http%3A%2F%2Fexample.com%2Fauth&scope=ViewReports%2CCreateCampaigns%2CSendCampaigns', '$authorize_url is as expected');

# Get authorize_url including state
$authorize_url = Net::CampaignMonitor->authorize_url(
  client_id => 8998879,
  redirect_uri => 'http://example.com/auth',
  scope => 'ViewReports,CreateCampaigns,SendCampaigns',
  state => 89879287
);

ok(Params::Util::_STRING($authorize_url), '$authorize_url is a string');
ok($authorize_url eq 'https://api.createsend.com/oauth?client_id=8998879&redirect_uri=http%3A%2F%2Fexample.com%2Fauth&scope=ViewReports%2CCreateCampaigns%2CSendCampaigns&state=89879287', '$authorize_url is as expected');

# Exchange OAuth token for access code - error case
throws_ok {
  my $token_details = Net::CampaignMonitor->exchange_token(
    client_id => -432109,
    client_secret => "not so secret",
    redirect_uri => "https://example.com",
    code => "code" ) }
  qr/^Error exchanging OAuth code for access token.*/,
  'exchange_token() should croak() if there is an error response from the OAuth receiver';

# Refresh OAuth token error case - no refresh token set
my $cm_refresh_error_no_token_set = Net::CampaignMonitor->new({
  secure  => 1
});

throws_ok {
  $cm_refresh_error_no_token_set->refresh_token() }
  qr/^Error refreshing OAuth token. No refresh token exists./,
  'refresh_token() should croak() if there is no refresh token set';

# Refresh OAuth token error case - error response from OAuth receiver
my $cm_refresh_error_from_post = Net::CampaignMonitor->new({
  secure  => 1,
  access_token => 'my access token',
  refresh_token => 'my refresh token'
});

throws_ok {
  $cm_refresh_error_from_post->refresh_token() }
  qr/^Error refreshing OAuth token. invalid_grant: Specified refresh_token was invalid or expired/,
  'refresh_token() should croak() if there is an error response from the OAuth receiver';
