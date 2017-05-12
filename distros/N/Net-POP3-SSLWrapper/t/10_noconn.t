use strict;
use warnings;
use Test::More tests => 1;

use Net::POP3;
use Net::POP3::SSLWrapper;

pop3s {
    ok(!Net::POP3->new('pop3.example.com'), 'Expected connection failure');
};

