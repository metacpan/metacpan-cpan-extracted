#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use Net::CampaignMonitor;
use Params::Util qw{_STRING};

my $api_key = '';
my $cm;

if ( Params::Util::_STRING($ENV{'CAMPAIGN_MONITOR_API_KEY'}) ) {
  $api_key = $ENV{'CAMPAIGN_MONITOR_API_KEY'};
  $cm = Net::CampaignMonitor->new({
    secure  => 1,
    api_key => $api_key,
    domain => (defined($ENV{'CAMPAIGN_MONITOR_DOMAIN'}) ?
      $ENV{'CAMPAIGN_MONITOR_DOMAIN'} : 'api.createsend.com'),
  });
}

SKIP: {
	skip 'Invalid API Key supplied', 2 if $api_key eq '';

	my $client_id = $cm->account_clients()->{response}->[0]->{ClientID};
	my $list_id   = $cm->client_lists($client_id)->{response}->[0]->{ListID};

	ok( $cm->list_delete($list_id)->{code} eq '200', 'Deleted list');
	ok( $cm->client_delete($client_id)->{code} eq '200', 'Deleted client' );
}