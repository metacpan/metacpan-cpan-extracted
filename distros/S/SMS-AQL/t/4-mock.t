#!/usr/bin/perl

# Tests for SMS::AQL using a mocked interface
#
# Thanks to Ton Voon @ Altinity (www.altinity.com) for providing this
# set of tests!
#
# $Id$

use strict;

use Test::More;
use LWP::UserAgent;


eval "use Test::MockObject::Extends";
plan skip_all => "Test::MockObject::Extends required for mock testing" 
    if $@;
    
# OK, we've got Test::MockObject::Extends, so we can go ahead:
plan tests => 92;


# NOTE - the test username and password is for testing SMS::AQL *only*,
# not to be used for any other purpose.  It is given a small amount of
# credit now and then, if you try to abuse it, it just won't get given
# any more credit.  So don't.
my $test_user = 'test_user';
my $test_pass = 'test_password';


use lib '../lib/';
use_ok('SMS::AQL');

my $warning;
my $sender;

# Catch warnings to test
local $SIG{__WARN__} = sub { $warning=shift };

$_ = SMS::AQL->new( { username => "this" } );
is($_, undef, "Fails to create new instance with only username");
like($warning, '/^Must supply username and password/', "Correct error message");

$_ = SMS::AQL->new( { password => "that" } );
is($_, undef, "Fails to create new instance with only password");
like($warning, '/^Must supply username and password/', "Correct error message");

$_ = SMS::AQL->new();
is($_, undef, "Fails to create new instance");
like($warning, '/^Must supply username and password/', "Correct error message");


ok($sender = new SMS::AQL({username => $test_user, password => $test_pass}), 
    'Create instance of SMS::AQL');

ok(ref $sender eq 'SMS::AQL', 
    '$sender is an instance of SMS::AQL');

# This wraps the ua so that methods can be overridden for testing purposes
my $mocked_ua = $sender->{ua} = Test::MockObject::Extends->new( $sender->{ua} );


$mocked_ua->mock("post", \&check_credit);
my $balance = $sender->credit();
is($balance, 501, "got account balance $balance");
is($sender->last_response, "AQSMS-CREDIT=501", "Got reply correctly");
is($sender->last_status, 1, "OK state");

sub check_credit {
	my ($self, $server, $postdata) = @_;
	my $expected = { username => "test_user", password => "test_password", cmd => "credit" };

	like( $server, '/^http:\/\/.*\/sms\/postmsg.php$/', "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-CREDIT=501" } );
	return $res;
}

$sender->{user} = "wrong_user";
$mocked_ua->mock( "post", \&check_credit_wrong_credentials );
$balance = $sender->credit;
is($balance, undef, "No balance received");
is($sender->last_response, "AQSMS-AUTHERROR", "Response gives AUTHERROR message");
is($sender->last_response_text, "The username and password supplied were incorrect", "Got nice text too");
is($sender->last_error, $sender->last_response_text, "And saved to last_error too");
is($sender->last_status, 0, "Error state");

sub check_credit_wrong_credentials {
	my ($self, $server, $postdata) = @_;
	my $expected = { username => "wrong_user", password => "test_password", cmd => "credit" };

	like( $server, '/^http:\/\/.*\/sms\/postmsg.php$/', "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-AUTHERROR" } );
	return $res;
}

$mocked_ua->mock( "post", sub { my $r = Test::MockObject->new(); $r->set_false( "is_success" ); return $r; } );
$balance = $sender->credit;
is($balance, undef, "No server available");
is($sender->last_error, "Could not get valid response from any server", "Correct error message");
is($sender->last_status, 0, "Error state");


my $rc = $sender->send_sms( "000", "Test text" );
is($rc, 0, "Sending failure due to no originator");
is($sender->last_error, "Cannot send message without sender specified", "And last_error set correctly");
is($sender->last_status, 0, "Error state");
like( $warning, '/^Cannot send message without sender specified/', "And right warning" );






#
# Sending tests
#
diag("Testing sending text, simulating all servers failing");
$sender->{user} = "test_user";
$mocked_ua->mock("post", 
    sub { 
        my $r = Test::MockObject->new(); 
        $r->set_false( "is_success" ); 
        return $r; 
    }
);
$rc = $sender->send_sms( "000", "Test text", { sender => "Altinity" } );
is($rc, 0, "No server available");
is($sender->last_error, "Could not get valid response from any server", 
    "Correct error message");
is($sender->last_status, 0, "Error state");


diag("Testing sending text, simulating success");
$mocked_ua->mock("post", \&send_text);
$rc = $sender->send_sms("000", "Testing text", { sender => "Altinity" });
is($rc, 1, "Successful send");
is($sender->last_response, "AQSMS-OK:1", "Got reply correctly");
is($sender->last_response_text, "OK", "Got text correctly");
is($sender->last_status, 1, "OK state");

my $message;
($rc, $message) = 
    $sender->send_sms("000", "Testing text", { sender => "Altinity" });
is($rc, 1, "Successful send on an array interface");
is($message, "OK", "With right message");
is($sender->last_status, 1, "OK state");

sub send_text {
	my ($self, $server, $postdata) = @_;
	my $expected = { 
        username => "test_user", 
        password => "test_password",
        orig     => "Altinity",
        to_num   => "000",
        message => "Testing text"
    };

	like($server, '/^http:\/\/.*\/sms\/postmsg-concat.php$/', 
        "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-OK:1" } );
	return $res;
}

diag("Testing sending text to invalid destination");
# I could only get an "AQSMS-INVALID_DESTINATION if I set the to_num as "bob".
# Setting a mobile number with a digit short, or 000 would still go through 
# as AQSMS-OK. However, SMS::AQL tries to cleanup the number, so using bob 
# fails because the postdata return "ob" instead. So for now, it makes sense 
# to just put a dummy number in because this is really a test for AQL's server
# - we just need to make sure we process this reply correctly.

$mocked_ua->mock("post", \&send_text_invalid_destination);
$rc = $sender->send_sms( "000", "Testing text to invalid dest", { sender => "Altinity" } );
is($rc, 0, "Expected error");
is($sender->last_response, "AQSMS-INVALID_DESTINATION", "Got expected reply");
is($sender->last_response_text, "Invalid destination", "Got text correctly");
is($sender->last_status, 0, "Error state");

($rc, $message) = $sender->send_sms( "000", "Testing text to invalid dest", { sender => "Altinity" } );
is($rc, 0, "Expected error on an array interface");
is($message, "Invalid destination", "With right message");
is($sender->last_status, 0, "Error state");

sub send_text_invalid_destination {
	my ($self, $server, $postdata) = @_;
	my $expected = { username => "test_user", password => "test_password", orig => "Altinity", to_num => "000", message=>"Testing text to invalid dest" };

	like( $server, '/^http:\/\/.*\/sms\/postmsg-concat.php$/', "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-INVALID_DESTINATION" } );
	return $res;
}


diag("Testing sending text, simulating failure due to no credit");
$mocked_ua->mock("post", \&send_text_no_credits);
$rc = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error");
is($sender->last_response, "AQSMS-NOCREDIT", "Got expected reply");
is($sender->last_response_text, "Out of credits", "Got text correctly");
is($sender->last_status, 0, "Error state");

($rc, $message) = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error on an array interface");
is($message, "Out of credits", "With right message");
is($sender->last_status, 0, "Error state");

sub send_text_no_credits {
	my ($self, $server, $postdata) = @_;
	my $expected = {
            username => "test_user",
            password => "test_password",
            orig     => "Altinity",
            to_num   => "000",
            message  => "Testing text to invalid dest"
    };

	like($server, qr{^http://.*/sms/postmsg-concat.php$}, 
        "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-NOCREDIT" } );
	return $res;
}

diag("Testing sending text, simulating unexected response");
$mocked_ua->mock("post", \&send_text_unexpected_response);
$rc = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error");
is($sender->last_response, "AQSMS-NOTPROPER", "Got expected reply");
is($sender->last_response_text, 
    "Unrecognised response from server: AQSMS-NOTPROPER", "Got text correctly");
is($sender->last_status, 0, "Error state");


diag("Testing sending text, simulating invalid destination");
($rc, $message) = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error on an array interface");
is($message, "Unrecognised response from server: AQSMS-NOTPROPER",
    "With right message");
is($sender->last_status, 0, "Error state");

sub send_text_unexpected_response {
	my ($self, $server, $postdata) = @_;
	my $expected = {
        username => "test_user",
        password => "test_password",
        orig     => "Altinity",
        to_num   => "000",
        message  => "Testing text to invalid dest"
    };

	like($server, qr{^http://.*/sms/postmsg-concat.php$}, 
        "Server correct format: $server");
	is_deeply( $postdata, $expected, "Post data correct" );

	my $res = Test::MockObject->new();
	$res->set_true( "is_success" );
	$res->mock( "content", sub { "AQSMS-NOTPROPER" } );
	return $res;
}


$mocked_ua->mock( "post", 
    sub { 
        my $r = Test::MockObject->new();
        $r->set_false( "is_success" );
        return $r; 
    }
);
$rc = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error: No server available");
is($sender->last_error, "Could not get valid response from any server", 
    "Correct error message");
is($sender->last_status, 0, "Error state");

diag("Testing sending text, simulating all servers failing");
($rc, $message) = $sender->send_sms(
    "000", "Testing text to invalid dest", { sender => "Altinity" }
);
is($rc, 0, "Expected error: No server available");
is($message, "Could not get valid response from any server", 
    "With right message");
is($sender->last_status, 0, "Error state");




# now test new voice push functionality
diag("Testing voice push functionality");
$mocked_ua->mock("post", \&voice_push);
$rc = $sender->voice_push("000", "Testing voice");
is($rc, 1, 'Successful voice push send');
is($sender->last_response,      "VP_OK", "Got reply correctly" );
is($sender->last_response_text, "OK",         "Got text correctly"  );
is($sender->last_status,         1,           "OK state"            );

($rc, $message) = $sender->voice_push( "000", "Testing voice");
is($rc,                  1,    "Successful send on an array interface");
is($message,             "OK", "With right message"                   );
is($sender->last_status, 1,    "OK state"                             );

sub voice_push {
    my ($self, $server, $postdata) = @_;
    my $expected = { 
        username => "test_user", 
        password => "test_password", 
        msisdn   => "000", 
        message  => "Testing voice" 
    };

    like( $server, qr{^http://vp\d\.aql\.com/voice_push.php$}, 
        "Server correct format: $server");
    is_deeply( $postdata, $expected, "Post data correct" );

    my $res = Test::MockObject->new();
    $res->set_true( "is_success" );
    $res->mock( "content", sub { "VP_OK" } );
    return $res;
}

# TODO: write further tests for the voice push functionality, to ensure it
# handles all possible AQL responses correctly.