# -*- perl -*-

use strict;
use warnings;
use Test::More;
use POSIX qw(strftime);
use HTTP::Request;

use Net::Amazon::SignatureVersion4;
my $sig=new Net::Amazon::SignatureVersion4();
my $hr=HTTP::Request->new('GET','/-/vaults', [ 
			      'Host', 'glacier.us-west-2.amazonaws.com', 
			      'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(1329307200)) , 
			      'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(1329307200)) , 
			      'x-amz-glacier-version', '2012-06-01',
			  ]);
$hr->protocol('HTTP/1.1');
$sig->set_request($hr);
my $key = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY';
my $dateStamp = '20120215';
my $regionName = 'us-east-1';
my $serviceName = 'iam';

#kSecret  = '41575334774a616c725855746e46454d492f4b374d44454e472b62507852666943594558414d504c454b4559'
#kDate    = '969fbb94feb542b71ede6f87fe4d5fa29c789342b0f407474670f0c2489e0a0d'
#kRegion  = '69daa0209cd9c5ff5c8ced464a696fd4252e981430b10e3d3fd8e2f197d7a70c'
#kService = 'f72cfd46f26bc4643f06a11eabb6c0ba18780c19a8da0c31ace671265e3c87fa'
#kSigning = 'f4780e2d9f65fa895f9c67b32ce1baf0b0d8a43505a000a1a9e090d414db404d'

$sig->set_date_stamp($dateStamp);
$sig->set_Secret_Access_Key($key);
$sig->set_region($regionName);
$sig->set_service($serviceName);
my %dk=$sig->get_derived_signing_key();
ok(unpack('H*',$dk{'kSecret'}) eq '41575334774a616c725855746e46454d492f4b374d44454e472b62507852666943594558414d504c454b4559', "kSecret");
ok(unpack('H*',$dk{'kDate'}) eq '969fbb94feb542b71ede6f87fe4d5fa29c789342b0f407474670f0c2489e0a0d', "kDate");
ok(unpack('H*',$dk{'kRegion'}) eq '69daa0209cd9c5ff5c8ced464a696fd4252e981430b10e3d3fd8e2f197d7a70c', "kRegion");
ok(unpack('H*',$dk{'kService'}) eq 'f72cfd46f26bc4643f06a11eabb6c0ba18780c19a8da0c31ace671265e3c87fa', "kService");
ok(unpack('H*',$dk{'kSigning'}) eq 'f4780e2d9f65fa895f9c67b32ce1baf0b0d8a43505a000a1a9e090d414db404d', "kSigning");
done_testing();
