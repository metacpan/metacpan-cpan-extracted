#!/opt/perl/bin/perl

use strict;
use FindBin;
use SMS::Send;

my $sender = SMS::Send->new( 'TMC', _login => 'myuser@example.com', _password => 'MySecurePassword' );

if ( !$sender ) {
    die "Failed to create instance of SMS::Send using SMS::Send::TMC driver";
}

$sender->send_sms(
    to         => '81771',
    text       => 'vote yes',
    _reference => 'My vote'
) or die "Failed to send message";

