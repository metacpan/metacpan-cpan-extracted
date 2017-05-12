#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

BEGIN {
    unshift @INC, "$Bin/../lib";
    use_ok( 'Net::SNMP::Poller' ) || print "Bail out!\n";
}

diag( "Testing Net::SNMP::Poller $Net::SNMP::Poller::VERSION, Perl $], $^X" );

my $obj = Net::SNMP::Poller->new();
isa_ok( $obj, 'Net::SNMP::Poller' );

my $ref = {
    'localhost' => {
        community => 'public',
        version   => 1,
        varbindlist => [ '.1.3.6.1.4.1.2021.11.50.0' ],
    },
    '127.0.0.1' => { # purposely reusing localhost as a different host
        varbindlist => [ '.1.3.6.1.4.1.2021.11.54.0' ],
    }
};


{
    # overwriting run() method as in reality it launches SNMP queries
    no warnings qw(once redefine);
    local *Net::SNMP::Poller::run = sub {
        return {
            'localhost' => {
                '.1.3.6.1.4.1.2021.11.50.0' => 414695
            }
        };
    };
    my $data = $obj->run( $ref );
    isa_ok( $data, 'HASH', 'run() overwritten test' );
}

done_testing();