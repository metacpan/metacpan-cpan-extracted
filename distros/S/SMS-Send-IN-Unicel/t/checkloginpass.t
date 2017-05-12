#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use SMS::Send;

#####################################################################
# Testing creation of new sender object with account credentials

# Create a new sender
my $sender = SMS::Send->new( 'IN::Unicel',
	_login    => 'foo',
	_password => 'bar',
	);
isa_ok( $sender, 'SMS::Send' );

# Test some internals
isa_ok( $sender->_OBJECT_, 'SMS::Send::IN::Unicel' );
is( $sender->_OBJECT_->{_login},    'foo',
	'Login set correctly in internals' );
is( $sender->_OBJECT_->{_password}, 'bar',
	'Password set correctly in internals' );

exit(0);
