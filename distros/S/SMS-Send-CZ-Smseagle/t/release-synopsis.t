#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use SMS::Send;

my $sender = SMS::Send->new('CZ::Smseagle',
    _login    => 'test',
    _password => 'dontknow'
);

ok (defined $sender,							'SMS::Send->new returned something');
isa_ok ($sender, 'SMS::Send',						'  and it\'s instance of SMS::Send');
