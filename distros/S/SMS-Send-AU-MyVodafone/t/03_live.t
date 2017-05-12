#!/usr/bin/perl

# Try to make sure the website is actually there

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use SMS::Send ();

my $login    = $ENV{SMS_LOGIN};
my $password = $ENV{SMS_PASSWORD};
my $to       = $ENV{SMS_TO};
my $text     = $ENV{SMS_TEXT} || "Testing SMS::Send::AU::MyVodafone";
if ( $login and $password and $to ) {
	plan( tests => 2 );
} else {
	plan( skip_all => "Set environment variables SMS_LOGIN, SMS_PASSWORD and SMS_TO to run a live test" );
}

sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Testing an actual working login

# Create a new sender
my $sender = SMS::Send->new( 'AU::MyVodafone',
	_login    => $login,
	_password => $password,
	);
isa_ok( $sender, 'SMS::Send' );

# Send a real message
my $rv = $sender->send_sms(
	text => $text,
	to   => $to,
	);
ok( $rv, '->send_sms sends a live message ok' );

