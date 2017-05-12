#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use SMS::Send;

my $sender = SMS::Send->new('CZ::Neogate',
    _login    => 'test',
    _password => 'dontknow'
);

ok (defined $sender,							'SMS::Send->new returned something');
isa_ok ($sender, 'SMS::Send',						'  and it\'s instance of SMS::Send');
is ($sender->send_sms(text => 'Test SMS', to => '604944755'),	0,	'Test message not sent, but it\'s OK, we don\'t know any credentials');
