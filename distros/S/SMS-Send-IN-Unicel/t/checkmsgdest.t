#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Exception tests => 5;
use SMS::Send; 

  # Create a sender
  my $sender = SMS::Send->new(
      'IN::Unicel',
      _login    => 'username',
      _password => 'password',
  );

# test 160 char length of message
dies_ok { $sender, _MESSAGETEXT('Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.') } '_MESSAGETEXT() dies with more than 160 characters';

dies_ok { $sender, _TO('819830098300') } ' _TO() dies with bad country code i.e. not 91';
dies_ok { $sender, _TO('98300983') } ' _TO() dies with invalid phone number format, less than 10';
dies_ok { $sender, _TO('983009830098300') } ' _TO() dies with invalid phone number format, more than 10';
dies_ok { $sender, _TO('916830098300') } ' _TO() dies with invalid phone number i.e. not 9/8/7';

exit(0);
