#!perl

# checking that invertion works the way we think it should

use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use Net::IPAddress::Minimal 'invert_ip';

{
    no warnings qw/redefine once/;

    *Net::IPAddress::Minimal::test_string_structure = sub {
        cmp_ok( scalar @_, '==', 1, 'no. of param test_string_structure()' );
        is( $_[0], 'test', 'correct param for test_string_structure()' );
        return 'waka waka';
    };
}

throws_ok { invert_ip('test') }
    qr{^Could not convert IP string / number due to unknown error},
    'invert_ip() can really die';

