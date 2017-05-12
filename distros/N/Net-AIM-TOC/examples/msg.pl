#!/usr/bin/perl -w

# This script illustrates the API of the Message object - useful
# if you are wanting to mak extensive use Net::AIM::TOC.

use strict;

use Error qw( :try );

use Net::AIM::TOC::Message;
use Net::AIM::TOC::Error;

my $messages = [
	'',
	'ERROR:983',
	'ERROR:902:test_im',
	'ERROR:901:test_im',
	'IM_IN:test_im:F:test',
	'UPDATE_BUDDY:test_im:T:0:1021475933:0: U',
	'SIGN_ON:TOC1.0',
];

my $id = $ARGV[0] || 0;

my $data = $messages->[$id];

my $msg;

try {
	$msg = Net::AIM::TOC::Message->new( 2, $data );

	print 'Type: '. $msg->getType ."\n";
	print 'Msg:  '. $msg->getMsg ."\n";
	print 'Data: '. $msg->getRawData ."\n";

}
catch Net::AIM::TOC::Error with {
	my $err = shift;
	print $err->stringify, "\n";

};

