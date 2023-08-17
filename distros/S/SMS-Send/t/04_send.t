#!/usr/bin/perl

# Test the sending of a message

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use SMS::Send;

use Params::Util '_INSTANCE';
sub dies_like {
	my $code   = shift;
	my $regexp = _INSTANCE(shift, 'Regexp')
		or die "Did not provide regexp to dies_like";
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Good Send

# Create a new test sender
SCOPE: {
	my $sender1 = SMS::Send->new( 'Test' );
	isa_ok( $sender1, 'SMS::Send' );
	is( $sender1->clear, 1, 'Methods pass through to the driver' );

	# Send the message
	my $rv = $sender1->send_sms(
		text     => 'This is a test',
		to       => '+61 (4) 1234 5678',
		ignore   => 'asdf',
		_private => 'value',
		);
	is( $rv, 1, '->send_sms returns true' );

	# Get the sent message
	my @messages = $sender1->messages;
	is_deeply( \@messages, [ [
		text     => 'This is a test',
		to       => '+61412345678',
		_private => 'value',
		] ], 'Message gets send as expected' );
}





#####################################################################
# Bad Sending

my $sender = SMS::Send->new( 'Test' );
isa_ok( $sender, 'SMS::Send' );
is( $sender->clear, 1, 'Methods pass through to the driver' );

dies_like(
	sub { $sender->send_sms() },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => undef ) },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => '' ) },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => \'' ) },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => [] ) },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => {} ) },
	qr/Did not provide a 'text' string param/,
);

dies_like(
	sub { $sender->send_sms( text => 'foo' ) },
	qr/Did not provide a 'to' message destination/,
);

dies_like(
	sub { $sender->send_sms( text => 'foo', to => undef ) },
	qr/Did not provide a 'to' message destination/,
);

dies_like(
	sub { $sender->send_sms( text => 'foo', to => '' ) },
	qr/Did not provide a 'to' message destination/,
);

dies_like(
	sub { $sender->send_sms( text => 'foo', to => ' ' ) },
	qr/Did not provide a 'to' message destination/,
);

dies_like(
	sub { $sender->send_sms( text => 'foo', to => '()' ) },
	qr/Did not provide a 'to' message destination/,
);
