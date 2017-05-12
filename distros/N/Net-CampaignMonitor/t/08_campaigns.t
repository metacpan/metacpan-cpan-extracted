#!/usr/bin/perl

use strict;
use Test::More tests => 18;
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
	skip 'Invalid API Key supplied', 18 if $api_key eq '';

	my $client_id = $cm->account_clients()->{response}->[0]->{ClientID};
	my $list_id   = $cm->client_lists($client_id)->{response}->[0]->{ListID};

	my %campaign = (
		  'ListIDs' => [ $list_id, ],
		  'FromName' => 'My Name',
		  'TextUrl' => 'http://media.netcomm.com.au/public/assets/file/0003/70833/full_width.html',
		  'Subject' => 'My Subject',
		  'HtmlUrl' => 'http://media.netcomm.com.au/public/assets/file/0003/70833/full_width.html',
		  'SegmentIDs' => [],
		  'FromEmail' => 'myemail@mydomain.com',
		  'Name'      => 'My Campaign Name'.time,
		  'ReplyTo'   => 'myemail@mydomain.com',
		  'clientid'  => $client_id
		);

	my $created_campaign = $cm->campaigns(%campaign);

	ok( $created_campaign->{code} eq '201', 'Draft campaign created' );

	my $campaign_id = $created_campaign->{response};

	my %campaign_schedule = (
		  'SendDate'          => '2016-01-01',
		  'ConfirmationEmail' => 'myemail@example.com',
		  'campaignid'        => $campaign_id
	);

	my %campaign_unschedule = (
		  'campaignid'        => $campaign_id
	);

	my %campaign_send = (
		  'SendDate'          => 'Immediately',
		  'ConfirmationEmail' => 'myemail@example.com',
		  'campaignid'        => $campaign_id
	);

	my %campaign_sendpreview = (
		  'PreviewRecipients' => [
					   'test1@example.com',
					   'test2@example.com'
					 ],
		  'Personalize'       => 'Random',
		  'campaignid'        => $campaign_id
	);

	my %paging_info = (
		'page'           => '1',
		'pagesize'       => '100',
		'orderfield'     => 'email',
		'orderdirection' => 'asc',
		'campaignid'     => $campaign_id,
	);

	my %paging_info_date = (
		'date'           => '1900-01-01',
		'page'           => '1',
		'pagesize'       => '100',
		'orderfield'     => 'email',
		'orderdirection' => 'asc',
		'campaignid'     => $campaign_id,
	);

	ok( $cm->campaigns_send(%campaign_schedule)->{code} eq '200', 'Campaign scheduled' );
	ok( $cm->campaigns_unschedule(%campaign_unschedule)->{code} eq '200', 'Campaign unscheduled' );
	ok( $cm->campaigns_send(%campaign_send)->{code} eq '200', 'Campaign sent' );
	ok( $cm->campaigns_sendpreview(%campaign_sendpreview)->{code} eq '200', 'Campaign send previews' );
	ok( $cm->campaigns_summary($campaign_id)->{code} eq '200', 'Campaign summary' );
	ok( $cm->campaigns_emailclientusage($campaign_id)->{code} eq '200', 'Campaign email client usage' );
	ok( $cm->campaigns_listsandsegments($campaign_id)->{code} eq '200', 'Campaign lists and segments' );
	ok( $cm->campaigns_recipients(%paging_info)->{code} eq '200', 'Campaign recipients' );
	ok( $cm->campaigns_bounces(%paging_info)->{code} eq '200', 'Campaign bounces' );
	ok( $cm->campaigns_opens(%paging_info_date)->{code} eq '200', 'Campaign opens' );
	ok( $cm->campaigns_clicks(%paging_info_date)->{code} eq '200', 'Campaign clicks' );
	ok( $cm->campaigns_unsubscribes(%paging_info_date)->{code} eq '200', 'Campaign unsubscribes' );
	ok( $cm->campaigns_spam(%paging_info_date)->{code} eq '200', 'Campaign spam complaints' );
	ok( $cm->campaigns_delete($campaign_id)->{code} eq '200', 'Campaign deleted' );
	
	# Create a campaign using the template created in 07_templates.t
	my $template_id = $cm->client_templates($client_id)->{'response'}->[0]->{TemplateID};
  my $template_content = {
    'Singlelines' => [
      {
        'Content' => "This is a heading",
        'Href' => "http://example.com/"
      }
    ],
    'Multilines' => [
      {
        'Content' => "<p>This is example</p><p>multiline <a href=\"http://example.com\">content</a>...</p>"
      }
    ],
    'Images' => [
      {
        'Content' => "https://dl.dropbox.com/u/884452/cm/perl/images/one.jpg",
        'Alt' => "This is alt text for an image",
        'Href' => "http://example.com/"
      }
    ],
    'Repeaters' => [
      {
        'Items' => [
          {
            'Layout' => "My layout",
            'Singlelines' => [
              {
                'Content' => "This is a repeater heading",
                'Href' => "http://example.com/"
              }
            ],
            'Multilines' => [
              {
                'Content' => "<p>This is example</p><p>multiline <a href=\"http://example.com\">content</a>...</p>"
              }
            ],
            'Images' => [
              {
                'Content' => "https://dl.dropbox.com/u/884452/cm/perl/images/two.jpg",
                'Alt' => "This is alt text for a repeater image",
                'Href' => "http://example.com/"
              }
            ]
          }
        ]
      }
    ],
  };

  my %campaign_fromtemplate = (
    'clientid'         => $client_id,
    'Name'             => 'Campaign from template',
    'Subject'          => 'Campaign from template',
    'FromName'         => 'My Name',
    'FromEmail'        => 'myemail@mydomain.com',
    'ReplyTo'          => 'myemail@mydomain.com',
    'ListIDs'          => [ $list_id, ],
    'SegmentIDs'       => [],
    'TemplateID'      => $template_id,
    'TemplateContent' => $template_content,
  );
  my $created_template_campaign = $cm->campaigns_fromtemplate(%campaign_fromtemplate);
  my $template_campaign_id = $created_template_campaign->{response};

  ok( $created_template_campaign->{code} eq '201', 'Template-based campaign created' );
  ok( $cm->campaigns_delete($template_campaign_id)->{code} eq '200', 'Template-based campaign deleted' );
  ok( $cm->templates_delete($template_id)->{code} eq '200', 'Deleted template used in campaign' );
}