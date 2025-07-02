#!/usr/bin/perl

use strict;
use Test::More tests => 7;
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
	skip 'Invalid API Key supplied', 7 if $api_key eq '';

	my $client_id = $cm->account_clients()->{response}->[0]->{ClientID};
	my $list_id   = $cm->client_lists($client_id)->{response}->[0]->{ListID};

  my %subscriber = (
    'Resubscribe'  => 'true',
    'RestartSubscriptionBasedAutoresponders' => 'true',
    'CustomFields' => [
      {
        'Value' => 'http://example.com',
        'Key'   => 'website'
      },
      {
        'Value' => 'magic',
        'Key'   => 'interests'
      },
      {
        'Value' => 'romantic walks',
        'Key'   => 'interests'
      }
    ],
    'Name'         => 'New Subscriber',
    'EmailAddress' => 'subscriber+stuff@example.com',
    'listid'       => $list_id,
  );

  my %update_subscriber = (
    'Resubscribe'  => 'true',
    'RestartSubscriptionBasedAutoresponders' => 'true',
    'CustomFields' => [
      {
        'Value' => 'http://example.com',
        'Key'   => 'website'
      },
      {
        'Value' => 'magic',
        'Key'   => 'interests'
      },
      {
        'Value' => '',
        'Key'   => 'interests',
        'Clear' => 'true'
      }
    ],
    'Name'         => 'Renamed Subscriber',
    'EmailAddress' => 'subscriber@example.com',
    'listid'       => $list_id,
    'email'        => 'subscriber+stuff@example.com'
  );

  my %new_subscribers = (
    'Subscribers' => [
      {
        'CustomFields' => [
          {
            'Value' => 'http://example.com',
            'Key' => 'website'
          },
          {
            'Value' => 'magic',
            'Key' => 'interests'
          },
          {
            'Value' => '',
            'Key' => 'interests',
            'Clear' => 'true'
          }
        ],
        'Name' => 'New Subscriber One',
        'EmailAddress' => 'subscriber1@example.com'
      },
      {
        'Name' => 'New Subscriber Two',
        'EmailAddress' => 'subscriber2@example.com'
      },
      {
        'Name' => 'New Subscriber Three',
        'EmailAddress' => 'subscriber3@example.com'
      }
    ],
    'Resubscribe' => 'true',
    'RestartSubscriptionBasedAutoresponders' => 'true',
    'QueueSubscriptionBasedAutoResponders' => 'false',
    'listid' => $list_id,
  );

	my %existing_subscriber = (
		'email'  => 'subscriber@example.com',
		'listid' => $list_id,
	);

	my %existing_subscriber2 = (
		'email'  => 'subscriber@example.com',
		'listid' => $list_id,
	);

	my %remove_subscriber = (
		'EmailAddress'  => 'subscriber@example.com',
		'listid'        => $list_id,
	);

	my %delete_subscriber = (
		'email'  => 'subscriber@example.com',
		'listid' => $list_id,
	);

	ok( $cm->subscribers(%subscriber)->{code} eq '201', 'Subscriber created' );
	ok( $cm->subscribers_update(%update_subscriber)->{code} eq '200', 'Subscriber updated' );
	ok( $cm->subscribers_import(%new_subscribers)->{code} eq '201', 'Subscribers created' );
	ok( $cm->subscribers(%existing_subscriber)->{code} eq '200', 'Got subscriber' );
	ok( $cm->subscribers_history(%existing_subscriber2)->{code} eq '200', 'Got subscriber history' );
	ok( $cm->subscribers_unsubscribe(%remove_subscriber)->{code} eq '200', 'Unsubscribed subscriber' );
	ok( $cm->subscribers_delete(%delete_subscriber)->{code} eq '200', 'Deleted subscriber' );
}
