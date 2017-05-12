# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
use Synapse::Logger;
use warnings;
use strict;

$Synapse::Logger::BASE_DIR = "./t/log";
logger ('this is a test1');
logger ('this is a test2');
ok (-e "t/log/t-00-base-t.log");

open FP, "t/log/t-00-base-t.log";
my $data = join '', <FP>;
close FP;
like ($data, qr /this is a test1/);
like ($data, qr /this is a test2/);



Test::More::done_testing();
