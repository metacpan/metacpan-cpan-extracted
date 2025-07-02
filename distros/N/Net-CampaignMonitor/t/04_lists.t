#!/usr/bin/perl

use strict;
use Test::More tests => 21;
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
	skip 'Invalid API Key supplied', 21 if $api_key eq '';

	my $client_id = $cm->account_clients()->{response}->[0]->{ClientID};

	my %list = (
		'Title'                   => 'Website Subscribers',
		'UnsubscribePage'         => 'http://www.example.com/unsubscribed.html',
		'UnsubscribeSetting'      => 'AllClientLists',
		'ConfirmedOptIn'          => 'false',
		'ConfirmationSuccessPage' => 'http://www.example.com/joined.html',
		'clientid'                => $client_id
	);

	my $created_list = $cm->lists(%list);

	ok( $created_list->{code} eq '201', 'Created client list' );

	my $list_id = $created_list->{'response'};

	my %update_list = (
		'Title'                     => 'Website Subscribers',
		'UnsubscribePage'           => 'http://www.example.com/unsubscribed.html',
		'UnsubscribeSetting'        => 'AllClientLists',
		'ConfirmedOptIn'            => 'false',
		'ConfirmationSuccessPage'   => 'http://www.example.com/joined.html',
    'AddUnsubscribesToSuppList' => 'true',
    'ScrubActiveWithSuppList'   => 'true',
		'listid'                    => $list_id
	);

	my %paging_info = (
		'date'           => '1900-01-01',
		'page'           => '1',
		'pagesize'       => '100',
		'orderfield'     => 'email',
		'orderdirection' => 'asc',
		'listid'         => $list_id,
	);

	my %custom_field = (
		'FieldName'                 => 'Newsletter Format',
		'DataType'                  => 'MultiSelectOne',
		'Options'                   => [ "HTML", "Text" ],
		'VisibleInPreferenceCenter' => 'true',
		'listid'                    => $list_id,
	);

	my %update_custom_field = (
	  'listid'                    => $list_id,
	  'customfieldkey'            => '[NewsletterFormat]',
	  'FieldName'                 => 'Newsletter Format Renamed',
	  'VisibleInPreferenceCenter' => 'false',
	);

	my %custom_field_options = (
		'KeepExistingOptions' => 'true',
		'Options'             => [ "First Option", "Second Option", "Third Option" ],
		'listid'              => $list_id,
		'customfieldkey'      => '[NewsletterFormatRenamed]',
	);

	my %custom_field_key = (
		'listid'         => $list_id,
		'customfieldkey' => '[NewsletterFormatRenamed]',
	);

	my %webhook = (
		'Events'        => [ "Subscribe" ],
		'Url'           => 'http://example.com/subscribe',
		'PayloadFormat' => 'json',
		'listid'        => $list_id,
	);

	ok( $cm->list_listid($list_id)->{code} eq '200', 'Got list details' );
	ok( $cm->list_stats($list_id)->{code} eq '200', 'Got list stats' );
	ok( $cm->list_customfields($list_id)->{code} eq '200', 'Got list customfields' );
	ok( $cm->list_segments($list_id)->{code} eq '200', 'Got list segments' );
	ok( $cm->list_active(%paging_info)->{code} eq '200', 'Got list active subscribers' );
	ok( $cm->list_unconfirmed(%paging_info)->{code} eq '200', 'Got list unconfirmed subscribers' );
	ok( $cm->list_unsubscribed(%paging_info)->{code} eq '200', 'Got list unsubscribed subscribers' );
	ok( $cm->list_deleted(%paging_info)->{code} eq '200', 'Got list deleted subscribers' );
	ok( $cm->list_bounced(%paging_info)->{code} eq '200', 'Got list bounced subscribers' );
	ok( $cm->list_listid(%update_list)->{code} eq '200', 'Updated list details' );
	ok( $cm->list_customfields(%custom_field)->{code} eq '201', 'List custom field created' );
	ok( $cm->list_customfields_update(%update_custom_field)->{code} eq '200', 'List custom field updated' );
	ok( $cm->list_options(%custom_field_options)->{code} eq '200', 'List custom field options updated' );
	ok( $cm->list_delete_customfieldkey(%custom_field_key)->{code} eq '200', 'Deleted list custom field' );
	ok( $cm->list_webhooks($list_id)->{code} eq '200', 'Got list webhooks' );

	my $created_webhook = $cm->list_webhooks(%webhook);

	ok( $created_webhook->{code} eq '201', 'Created webhook' );

	my $webhook_id = $created_webhook->{'response'};

	my %webhook_details = (
		'webhookid' => $webhook_id,
		'listid'    => $list_id,
	);

	ok( $cm->list_test(%webhook_details)->{code} eq '200', 'Tested webhook' );
	ok( $cm->list_activate(%webhook_details)->{code} eq '200', 'Activated webhook' );
	ok( $cm->list_deactivate(%webhook_details)->{code} eq '200', 'Deactivated webhook' );
	ok( $cm->list_delete_webhook(%webhook_details)->{code} eq '200', 'Deleted webhook' );
}