## Before `make install' is performed this script should be runnable with
## `make test'. After `make install' it should work as `perl Regexp-SAR.t'
#
##########################
#
## change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use utf8;


use Test::More;


BEGIN { use_ok('Regexp::SAR') };

##########################
#
## Insert your test code below, the Test::More module is use()ed here so read
## its man page ( perldoc Test::More ) for help writing this test script.
#
## is(Regexp::SAR::strLength('abc'), 3, "Test XS normal string length");
## is(Regexp::SAR::strLengthUtf8('abc'), 3, "Test XS normal string length");
## is(Regexp::SAR::strLengthUtf8('דוא'), 3, "Test XS UTF-8 string length");
#
#############################################
#
#
###############################################
done_testing();
