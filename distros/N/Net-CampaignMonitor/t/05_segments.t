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

	       my %segment = (
			 'Rules' => [
				      {
					'Subject' => 'EmailAddress',
					'Clauses' => [
						       'CONTAINS @domain.com'
						     ]
				      },
				      {
					'Subject' => 'DateSubscribed',
					'Clauses' => [
						       'AFTER 2009-01-01',
						       'EQUALS 2009-01-01'
						     ]
				      },
				      {
					'Subject' => 'DateSubscribed',
					'Clauses' => [
						       'BEFORE 2010-01-01'
						     ]
				      }
				    ],
			 'Title' => 'My Segment',
			 'listid' => $list_id,
	       );

	       my $created_segment = $cm->segments(%segment);

	       ok( $created_segment->{code} eq '201', 'Created segment' );

	       my $segment_id = $created_segment->{'response'};

	       my %updated_segment = (
			 'Rules' => [
				      {
					'Subject' => 'EmailAddress',
					'Clauses' => [
						       'CONTAINS @domain.com'
						     ]
				      },
				      {
					'Subject' => 'DateSubscribed',
					'Clauses' => [
						       'AFTER 2009-01-01',
						       'EQUALS 2009-01-01'
						     ]
				      },
				      {
					'Subject' => 'DateSubscribed',
					'Clauses' => [
						       'BEFORE 2010-01-01'
						     ]
				      }
				    ],
			 'Title' => 'My Segment',
			 'segmentid' => $segment_id,
	       );

	       my %rule = (
		 'Subject' => 'Name',
		 'Clauses' => [
				'NOT_PROVIDED',
				'EQUALS Subscriber Name'
			      ],
		 'segmentid' => $segment_id,
	       );

	       my %paging_info = (
		       'date'              => '1900-01-01',
		       'page'              => '1',
		       'pagesize'          => '100',
		       'orderfield'        => 'email',
		       'orderdirection'    => 'asc',
		       'segmentid'         => $segment_id,
	       );

	       ok( $cm->segment_segmentid(%updated_segment)->{code} eq '200', 'Segment updated' );
	       ok( $cm->segment_rules(%rule)->{code} eq '200', 'Segment rule added' );
	       ok( $cm->segment_segmentid($segment_id)->{code} eq '200', 'Segment details obtained' );
	       ok( $cm->segment_active(%paging_info)->{code} eq '200', 'Segment actives obtained' );
	       ok( $cm->segment_delete_rules($segment_id)->{code} eq '200', 'Segment rules deleted' );
	       ok( $cm->segment_delete($segment_id)->{code} eq '200', 'Segment deleted' );  
}