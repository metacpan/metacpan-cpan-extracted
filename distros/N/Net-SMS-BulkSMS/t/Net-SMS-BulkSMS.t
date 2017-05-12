# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-SMS-BulkSMS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Net::SMS::BulkSMS') };
use MIME::Base64;
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# to run this test you should register an account at www.bulksms.co.uk and set
# environment variables bulksms_user and bulksms_password to your account details
# then run the test
my $user = $ENV{bulksms_user}||'';
my $pass = $ENV{bulksms_password}||'';
diag "\nEnvironment variables bulksms_user and bulksms_password not set" unless $user && $pass;
# to test really sending an SMS to a phone number, which costs money, set 
# environment variable bulksms_send_isdn to the number including the 
# international country code, e.g. UK has country code 44 so for phone
# number 123123456 you bulksms_send_isdn to "44123123456"
my $send_isdn = $ENV{bulksms_send_isdn}||'';

SKIP: {
	skip 'Environment variables bulksms_user and bulksms_password not set, skipping tests', 2
			unless $user && $pass;

	my $sms = Net::SMS::BulkSMS->new (
		test      => 0, 
		username  => encode_base64("$user"),
		password  => encode_base64("$pass")
		);

	my ($msg,$code);

	($msg,$code) = $sms->quote_sms(message=>"Net::SMS::BulkSMS Testing 1",msisdn=>"44123123456",msg_class=>"0");
	diag "\nquote_sms: $msg\n";
	ok( $code == 1,		'quote_sms');

	($msg,$code) = $sms->get_credits;
	diag "\nget_credits: $msg\n";
	ok( $code == 1,		'get_credits');
}

SKIP: {
	skip 'Environment variable bulksms_send_isdn not set, skipping send/report tests', 2
		unless $user && $pass && $send_isdn;

	my $sms = Net::SMS::BulkSMS->new (
		test      => 0, 
		username  => encode_base64("$user"),
		password  => encode_base64("$pass")
		);

	my ($msg,$code,$result_hp);

	(my $msg_id,$code) = $sms->send_sms(message=>"Net::SMS::BulkSMS Testing 2", msisdn=>"$send_isdn");
	ok( $code == 1,		'send_sms');
	diag "\nsend_sms: $msg_id\n";

   ($msg,$code,$result_hp) = $sms->get_report(msg_id=>"$msg_id",msisdn=>"$send_isdn");
	ok( $code == 1,		'get_report');
	diag ("\nget_report: $msg, $code\n");
	diag Dumper($result_hp);
}
