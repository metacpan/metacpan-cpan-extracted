#!/usr/bin/perl

use strict;
use Test::More tests => 23;
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
	skip 'Invalid API Key supplied', 23 if $api_key eq '';

	my %new_client = (
		'CompanyName'  => "ACME Limited",
		'Country'      => "Australia",
		'TimeZone'     => "(GMT+10:00) Canberra, Melbourne, Sydney"
	);

	my $created_client = $cm->account_clients(%new_client);

	ok( $created_client->{'code'} eq '201', 'Client created' );

	my $client_id = $created_client->{'response'};

	my %basic_access_settings = (
		'AccessLevel' => '23',
		'clientid'    => $client_id,
	);

	my %access_settings = (
		'AccessLevel' => '23',
		'Username'    => 'jdoe',
		'Password'    => 'password',
		'clientid'    => $client_id,
	);

	my %paging_info = (
		'page'           => '1',
		'pagesize'       => '100',
		'orderfield'     => 'email',
		'orderdirection' => 'asc',
		'clientid'       => $client_id,
	);

	my %replace_client = (
		'CompanyName'  => "ACME Limited",
		'Country'      => "Australia",
		'TimeZone'     => "(GMT+10:00) Canberra, Melbourne, Sydney",
		'clientid'     => $client_id
	);

	my %payg = (
		'Currency'               => 'AUD',
		'CanPurchaseCredits'     => 'false',
		'ClientPays'             => 'true',
		'MarkupPercentage'       => '20',
		'MarkupOnDelivery'       => '5',
		'MarkupPerRecipient'     => '4',
		'MarkupOnDesignSpamTest' => '3',
		'clientid'               => $client_id,
	);

	my %credits = (
		'Credits'                       => '0',
		'CanUseMyCreditsWhenTheyRunOut' => 'true',
		'clientid'                      => $client_id,
	);

	my %monthly = (
		'Currency'               => 'AUD',
		'ClientPays'             => 'true',
		'MarkupPercentage'       => '20',
		'clientid'               => $client_id,
	);

  my %listsforemail = (
    'email' => 'example@example.com',
    'clientid' => $client_id,
  );

  my %suppress = (
    'EmailAddresses' => [ 'example123@example.com', 'example456@example.com' ],
    'clientid' => $client_id,
  );

  my %unsuppress = (
    'email' => 'example123@example.com',
    'clientid' => $client_id,
  );

	ok( $cm->client_clientid($client_id)->{code} eq '200', 'Got client details' );
	ok( $cm->client_campaigns($client_id)->{code} eq '200', 'Got client sent campaigns' );
	ok( $cm->client_drafts($client_id)->{code} eq '200', 'Got client draft campaigns' );
	ok( $cm->client_scheduled($client_id)->{code} eq '200', 'Got client scheduled campaigns' );
	ok( $cm->client_lists($client_id)->{code} eq '200', 'Got client subscriber lists' );
	ok( $cm->client_listsforemail(%listsforemail)->{code} eq '200', 'Got client lists for an email address' );
	ok( $cm->client_segments($client_id)->{code} eq '200', 'Got client segments' );
	ok( $cm->client_suppressionlist(%paging_info)->{code} eq '200', 'Got client suppression list' );
	ok( $cm->client_templates($client_id)->{code} eq '200', 'Got client templates' );
	ok( $cm->client_setbasics(%replace_client)->{code} eq '200', 'Set client basics' );
	ok( $cm->client_setpaygbilling(%payg)->{code} eq '200', 'Set client PAYG billing' );
	ok( $cm->client_transfercredits(%credits)->{code} eq '200', 'Transferred credits to client' );
	ok( $cm->client_setmonthlybilling(%monthly)->{code} eq '200', 'Set client monthly billing' );
	ok( $cm->client_suppress(%suppress)->{code} eq '200', 'Suppressed email addresses' );
	ok( $cm->client_unsuppress(%unsuppress)->{code} eq '200', 'Unsuppressed an email address' );

	my %new_person = (
		'clientid'     	=> $client_id,
		'EmailAddress'  => "joe.person\@example.com",
		'Name'          => "Joe Doeman",
		'AccessLevel'   => 23,
		'Password'      => "safepassword"
	);

	my %update_person = (
		'clientid'      => $client_id,
		'email'         => "joe.person\@example.com",
		'EmailAddress'  => "joe.new\@example.com",
		'Name'          => "Joe Doeman",
		'AccessLevel'   => 23,
		'Password'      => "safepassword"
	);

	my %person = (
		'clientid'      => $client_id,
		'email'         => "joe.new\@example.com",
	);

	my %another_person = (
		'clientid'     	=> $client_id,
		'EmailAddress'  => "another.person\@example.com",
		'Name'          => "Another Person",
		'AccessLevel'   => 23,
		'Password'      => "safepassword"
	);

	my %delete_person = (
		'clientid'      => $client_id,
		'email'         => "another.person\@example.com",
	);

	ok( $cm->client_addperson(%new_person)->{code} eq '201', 'Added new person' );
	ok( $cm->client_updateperson(%update_person)->{code} eq '200', 'Updated person' );
	ok( $cm->client_getpeople($client_id)->{code} eq '200', 'Got people' );
	ok( $cm->client_getperson(%person)->{code} eq '200', 'Got person' );
	ok( $cm->client_getprimarycontact($client_id)->{code} eq '200', 'Got person primary contact' );
	ok( $cm->client_addperson(%another_person)->{code} eq '201', 'Added new person' );
	ok( $cm->client_deleteperson(%delete_person)->{code} eq '200', 'Delete person' );
}