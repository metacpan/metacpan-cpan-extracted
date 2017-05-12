#!/usr/bin/perl

# Tests that hit the network

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use SMS::Send ();

my $accountid    = $ENV{SMS_ACCOUNTID};
my $password = $ENV{SMS_PASSWORD};
my $email    = $ENV{SMS_EMAIL};
my $to       = $ENV{SMS_TO};
my $text     = $ENV{SMS_TEXT} || "Testing SMS::Send::AU::MyVodafone";
if ( $accountid and $password and $to and $email ) {
	plan( tests => 3 );
} else {
	plan( skip_all => "Set environment variables SMS_ACCOUNTID, SMS_PASSWORD, SMS_EMAIL and SMS_TO to run a live test, eg SMS_ACCOUNTID=CI000000 SMS_PASSWORD=somepw SMS_EMAIL=someemail\@example.com make test" );
}

sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Testing an actual working login

my $sender = SMS::Send->new( 'RedOxygen',
		_accountid  => $accountid,
		_email      => $email,
		_password   => $password
	);
isa_ok( $sender, 'SMS::Send' );

my $rv;

# Send a message with a valid account to a bogus number
dies_like( sub {
	$rv = $sender->send_sms(
		text => 'Message should fail',
		to   => '+61999999999'
	); },
	qr/2015/
);

# Send a real message
$rv = $sender->send_sms(
	text => $text,
	to   => $to,
	);
ok( $rv, '->send_sms sends a live message ok' );
