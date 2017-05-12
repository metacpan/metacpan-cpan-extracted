# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Panda-Util.t'

#########################

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Panda::Export') };

done_testing();
