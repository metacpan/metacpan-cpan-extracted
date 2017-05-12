#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use SMS::Send;

#####################################################################
# Testing creation of new sender object with account credentials

# Create a new sender
my $sender = SMS::Send->new( 'IN::eSMS',
	_login    => 'foo',
	_password => 'bar',
        _senderid => 'gobar',
	);
isa_ok( $sender, 'SMS::Send' );

# Test some internals
isa_ok( $sender->_OBJECT_, 'SMS::Send::IN::eSMS' );
is( $sender->_OBJECT_->{_login},    'foo',
	'Login set correctly in internals' );
is( $sender->_OBJECT_->{_password}, 'bar',
	'Password set correctly in internals' );
is( $sender->_OBJECT_->{_senderid}, 'gobar',
        'SenderID set correctly in internals' );
exit(0);
