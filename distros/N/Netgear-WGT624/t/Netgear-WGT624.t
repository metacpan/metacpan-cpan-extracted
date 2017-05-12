#########################

use Test::More tests => 6;
BEGIN { use_ok('Netgear::WGT624') };

#########################

my $ng = Netgear::WGT624->new();
$ng->address('router-int');

# Test a variety of private methods to make sure that they return expected 
# results.

is($ng->_make_url, 'http://router-int/RST_stattbl.htm', 'make_url test 1');
is($ng->_make_url, 'http://router-int/RST_stattbl.htm', 'make_url test 2');

$ng->address('router-int/');

is($ng->_make_url, 'http://router-int/RST_stattbl.htm', 'make_url test 3');

is($ng->_get_server_address, 'router-int:80', 'get_server_address test 1');

$ng->address('router-int');
is($ng->_get_server_address, 'router-int:80', 'get_server_address test 2');
