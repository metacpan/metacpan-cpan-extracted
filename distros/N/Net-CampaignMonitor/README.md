# createsend-perl [![Build Status](https://secure.travis-ci.org/campaignmonitor/createsend-perl.png?branch=master)][travis]
A Perl library for the [Campaign Monitor API](http://www.campaignmonitor.com/api/).

[travis]: http://travis-ci.org/campaignmonitor/createsend-perl

## Installation

Download and install using CPAN:

```
cpan Net::CampaignMonitor
```

## Authenticating

The Campaign Monitor API supports authentication using either OAuth or an API key.

### Using OAuth

This library helps you authenticate using OAuth, as described in the Campaign Monitor API [documentation](http://www.campaignmonitor.com/api/getting-started/#authenticating_with_oauth). You may also wish to reference this Perl [example application](https://github.com/jdennes/perlcreatesendoauthtest/). The authentication process is described below.

The first thing your application should do is redirect your user to the Campaign Monitor authorization URL where they will have the opportunity to approve your application to access their Campaign Monitor account. You can get this authorization URL by using `Net::CampaignMonitor->authorize_url()`, like so:

```perl
use Net::CampaignMonitor;

my $authorize_url = Net::CampaignMonitor->authorize_url(
  client_id => 'Client ID for your application',
  redirect_uri => 'Redirect URI for your application',
  scope => 'The permission level your application requires',
  state => 'Optional state data to be included'
);
# Redirect your users to $authorize_url.
```

If your user approves your application, they will then be redirected to the `redirect_uri` you specified, which will include a `code` parameter, and optionally a `state` parameter in the query string. Your application should implement a handler which can exchange the code passed to it for an access token, using `Net::CampaignMonitor->exchange_token()` like so:

```perl
use Net::CampaignMonitor;

my $token_details = Net::CampaignMonitor->exchange_token(
  client_id => 'Client ID for your application',
  client_secret => 'Client Secret for your application',
  redirect_uri => 'Redirect URI for your application',
  code => 'A unique code for your user' # Get the code parameter from the query string
);
# Save $token_details->{access_token}, $token_details->{expires_in}, and $token_details->{refresh_token}
```

Once you have an access token and refresh token for your user, you can authenticate and make further API calls like so:

```perl
use Net::CampaignMonitor;
my $cm = Net::CampaignMonitor->new({
  access_token => 'your access token',
  refresh_token => 'your refresh token',
  secure  => 1,
});
my $clients = $cm->account_clients();
```

All OAuth tokens have an expiry time, and can be renewed with a corresponding refresh token. If your access token expires when attempting to make an API call, your code should handle the case when a `401 Unauthorized` response is returned with a Campaign Monitor error code of `121: Expired OAuth Token`. Here's an example of how you could do this:

```perl
use Net::CampaignMonitor;
my $cm = Net::CampaignMonitor->new({
  access_token => 'your access token',
  refresh_token => 'your refresh token',
  secure  => 1,
});
my $clients = $cm->account_clients();

# If you receive '121: Expired OAuth Token', refresh the access token
if ($clients->{code} eq '401' && $clients->{response}->{Code} eq '121') {
  my $result = $cm->refresh_token();
  # Save $result->{access_token}, $result->{expires_in}, and $result->{refresh_token}
  $clients = $cm->account_clients(); # Make the call again
}
```

### Using an API key

```perl
use Net::CampaignMonitor;
my $cm = Net::CampaignMonitor->new({
  api_key => 'abcd1234abcd1234abcd1234',
  secure  => 1,
});
my $clients = $cm->account_clients();
```

## Basic usage

This example of listing all your clients and their campaigns demonstrates basic usage of the library and the data returned from the API.

```perl
use Net::CampaignMonitor;

my $cm = Net::CampaignMonitor->new(
  secure => 1,
  access_token => 'your access token',
  refresh_token => 'your refresh token'
);

foreach $cl (@{$cm->account_clients()->{response}}) {
  print "Client: $cl->{Name}\n";
  print "- Campaigns:\n";
  foreach $ca (@{$cm->client_campaigns($cl->{ClientID})->{response}}) {
    print "  - $ca->{Subject}\n";
  }
}
```

## Documentation

Full documentation of the module is available on [CPAN](http://search.cpan.org/dist/Net-CampaignMonitor/lib/Net/CampaignMonitor.pm) or by using `perldoc`:

```
perldoc Net::CampaignMonitor
```

## Contributing

Please check the [guidelines for contributing](https://github.com/campaignmonitor/createsend-perl/blob/master/CONTRIBUTING.md) to this repository.
