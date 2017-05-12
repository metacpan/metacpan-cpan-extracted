#!perl
use strict;
use warnings FATAL => 'all';
use 5.014;

BEGIN {chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

BEGIN { use_ok('NetObj::IPv4Address'); }

is(
    ref(NetObj::IPv4Address->new('127.0.0.1')),
    'NetObj::IPv4Address',
    'NetObj::IPv4Address must be a class',
);
