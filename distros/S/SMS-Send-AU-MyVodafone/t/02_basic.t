#!/usr/bin/perl 

# Try to make sure the website is actually there

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use SMS::Send;

sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Test as many errors as we can without hitting the web

dies_like(
	sub { SMS::Send->new( 'AU::MyVodafone',
		login    => '0444 444 444',
		password => 'foobarbaz',
		) },
	qr/Did not provide a login/,
);






#####################################################################
# Testing up to the point of a working login

# Create a new sender
my $sender = SMS::Send->new( 'AU::MyVodafone',
	_login    => '0444 444 444',
	_password => 'foobarbaz',
	);
isa_ok( $sender, 'SMS::Send' );

# Test some internals
isa_ok( $sender->_OBJECT_, 'SMS::Send::AU::MyVodafone' );
is( $sender->_OBJECT_->{login},    '0444444444',
	'Login set correctly in internals' );
is( $sender->_OBJECT_->{password}, 'foobarbaz',
	'Password set correctly in internals' );
ok( ! $sender->_OBJECT_->{logged_in},
	'Driver does not login by default' );

# Can we get the login page
ok( $sender->_OBJECT_->_get_login,
	'Got the login page to myvodafone.com.au' );





#####################################################################
# More failures with an actual account

dies_like(
	sub { $sender->_OBJECT_->_send_login },
	qr/Invalid login and password/,
);

exit(0);
