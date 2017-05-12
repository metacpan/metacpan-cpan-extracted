# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $filepath 	= 't/net1.net';

use Test::More tests => 1; 
BEGIN { use_ok('RadioMobile') };

my $rm = new RadioMobile(debug => $ENV{'RM_DEBUG'} || 0);
$rm->filepath($filepath);
$rm->parse;
$rm->write;

