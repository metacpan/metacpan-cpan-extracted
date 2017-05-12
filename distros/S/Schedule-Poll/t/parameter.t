#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use Schedule::Poll;
ok ( Schedule::Poll->new({ foo => 5, bar => 600} ) );
ok ( Schedule::Poll->new({ foo => 300}) );

