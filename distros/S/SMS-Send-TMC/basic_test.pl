#!/opt/perl/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use SMS::Send;

my $sender = SMS::Send->new( 'TMC', _login => 'tmc@jrtheatre.co.uk', _password => 'text2jrcrew', _debug => 1 );

if ( !$sender ) {
    die "Failed to create instance of SMS::Send using SMS::Send::TMC driver";
}

$sender->send_sms(
    to         => '+447899990616',
    text       => 'This is a test message',
    _reference => 'Nigel Metheringham'
) or die "Failed to send message";

