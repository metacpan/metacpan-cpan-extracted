#!perl

use strict;

use Net::ILO;
use Test::More tests => 6;

my $err_msg = 'must be an integer between 0 and 65535';

ok( Net::ILO::_port_is_valid(0), '0 is a valid port number');
ok( Net::ILO::_port_is_valid(65535), '65535 is a valid port number');
ok( !Net::ILO::_port_is_valid(65536), '65535 + 1 is invalid');
ok( !Net::ILO::_port_is_valid(-1), 'negative numbers are not valid');
ok( !Net::ILO::_port_is_valid(''), 'empty string is invalid');

my $ilo;

eval { $ilo = Net::ILO->new({
    port     => 65536,
}); };

ok( $@ =~ $err_msg, 'invalid port in constructor throws fatal error' );

