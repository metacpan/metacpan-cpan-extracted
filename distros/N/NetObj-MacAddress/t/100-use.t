#!perl
use strict;
use warnings;
use 5.10.1;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

BEGIN { use_ok('NetObj::MacAddress'); }

is(
    ref(NetObj::MacAddress->new('001122334455')),
    'NetObj::MacAddress',
    'NetObj::MacAddress must be a class'
);
