# -*- perl -*-

use v5.32;
use utf8;
use warnings;
use open qw(:std :utf8);
no feature qw(indirect);
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Test::More;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Date;
use Net::Amazon::SignatureVersion4;
use POSIX qw(strftime);
use JSON;
use Data::Dumper;


 SKIP: {
     skip "Skipping live connection tests because AWS_ACCESS_KEY_ID and AWS_SECRET_KEY are not set", 1 unless (defined $ENV{'AWS_ACCESS_KEY_ID'} & defined $ENV{'AWS_SECRET_KEY'});

     my $sig=Net::Amazon::SignatureVersion4->new();
     
     my $hr=HTTP::Request->new('GET','http://glacier.us-west-2.amazonaws.com/-/vaults', [ 
				   'Host', 'glacier.us-west-2.amazonaws.com', 
				   'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'x-amz-glacier-version', '2012-06-01',
			       ]);
     $hr->protocol('HTTP/1.1');
     #diag($hr->as_string());
     
     $sig->set_request($hr);
     $sig->set_region('us-west-2');
     $sig->set_service('glacier');
     $sig->set_Access_Key_ID($ENV{'AWS_ACCESS_KEY_ID'});
     $sig->set_Secret_Access_Key($ENV{'AWS_SECRET_KEY'});
     my $r=$sig->get_authorized_request();
     #diag("REQUEST:");
     #diag(Data::Dumper->Dump([ $r ]));
     
     #diag("CANONICAL REQUEST");
     #diag($sig->get_canonical_request());
     #diag("STRING TO SIGN");
     #diag($sig->get_string_to_sign());
     #diag("ACTUAL HEADERS");
     #diag($r->as_string());
     
     my $agent = LWP::UserAgent->new( agent => 'perl-Net::Amazon::SignatureVersion4-Testing');
     my $response = $agent->request($r);
     if ($response->is_success) {
	 diag("List of vaults");
	 diag(Data::Dumper->Dump([ decode_json $response->decoded_content ]));  # or whatever
	 pass("Connected to live server");
     }
     else {
	 #say $response->status_line;
	 diag("RESPONSE:");
	 diag(Data::Dumper->Dump([ $response ]));
	 fail("Connected to live server");
     }
     
};

done_testing();
