#!perl

use strict;

use Net::ILO;
use Test::More tests => 3;

my $no_error = {
    'RESPONSE' => {
        'STATUS'  => '0x0000',
        'MESSAGE' => 'No error'
    },
    'VERSION' => '2.22'
};

my $error = {
    'RESPONSE' => {
        'STATUS'  => '0x0001',
        'MESSAGE' => 'Sample error message'
    },
    'VERSION' => '2.22'
};

# should return false when no error occurs

ok( !Net::ILO::_check_errors($no_error),                        'no error returned' );
ok( Net::ILO::_check_errors($error),                            'error returned' );
ok( Net::ILO::_check_errors($error) eq 'Sample error message',  'error message returned' );



