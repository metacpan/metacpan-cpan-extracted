#!/usr/bin/perl

# $Id: simple-example.pl 211 2008-01-19 15:30:31Z davidp $
#
# A very quick and simple usage example for SMS::Send::AQL

use strict;
use SMS::Send;


my $sender = SMS::Send->new('AQL', _username => 'user', _password => 'pass');

if (!$sender) {
    die "Failed to create instance of SMS::Send using SMS::Send::AQL driver";
}


$sender->send_sms(
    to   => '+447734123456',
    text => 'Text message content here',
) or die "Failed to send message";

