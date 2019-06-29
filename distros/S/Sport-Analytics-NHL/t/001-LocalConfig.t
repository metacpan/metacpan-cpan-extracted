#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

plan tests => 1;

use Sport::Analytics::NHL::LocalConfig;

isa_ok(\%LOCAL_CONFIG, 'HASH', 'Local config defined');
