#!/usr/bin/env perl 

use lib "../lib";
use Net::ThreeScale::Client;
use strict;

use POSIX qw(strftime);

my $provider_key = "provider key here";
my $app_id     = "app id here"; 
my $app_key     = "app key here"; 

my $client = new Net::ThreeScale::Client( provider_key => $provider_key );

my $response = $client->authorize( app_id=>$app_id, app_key=>$app_key );
if ( $response->is_success() ) {
	print "successfully authorized\n";
}
else {
	die( "failed to create transaction with error:", $response->error_code," " ,$response->error_message );
}

my @transactions = (
	{
		app_id => $app_id,
		usage => {
			hits => 10,
		},
		timestamp => strftime("%Y-%m-%d %H:%M:%S", localtime()),
	},
);

my $report_response = $client->report( transactions=>\@transactions);
if ( $report_response->is_success ) {
	print "successfully reported transactions\n";
}
else {
	die( "failed to cancel transaction with error:", $report_response->error );
}
