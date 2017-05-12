#!/usr/bin/perl 


use strict;

use Test::More tests => 6;
use SMS::Send;

# Borrowed from SMS::Send::AU::Vodafone
sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Test various missing parameters to ctor

dies_like(
	sub { SMS::Send->new( 'RedOxygen',
		_accountid  => 'CI00000000',
		_password   => 'foobarbaz'
		) },
	qr/The _email parameter must be set/,
);


dies_like(
	sub { SMS::Send->new( 'RedOxygen',
		_accountid  => 'CI00000000',
		_email      => 'some@example.com'
		) },
	qr/The _password parameter must be set/,
);


dies_like(
	sub { SMS::Send->new( 'RedOxygen',
		_password   => 'foobarbaz',
		_email      => 'some@example.com'
		) },
	qr/The _accountid parameter must be set/,
);


	

#####################################################################
# Offline, no-network tests

# Create a new sender
my $sender = SMS::Send->new( 'RedOxygen',
		_accountid  => 'CI00000000',
		_email      => 'some@example.com',
		_password   => 'foobarbaz'
	);

isa_ok( $sender, 'SMS::Send' );

dies_like(
	sub { $sender->send_sms( text => 'Test message' ); },
	qr/Did not provide a 'to' message destination/
);


dies_like(
	sub { $sender->send_sms( to => '+(61) 444 444 444' ); },
	qr/Did not provide a 'text' string param/
);

exit(0);
