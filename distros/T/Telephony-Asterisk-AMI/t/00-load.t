#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Telephony::Asterisk::AMI');
}

diag("Testing Telephony::Asterisk::AMI $Telephony::Asterisk::AMI::VERSION");
