#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

require Net::Async::Gearman;
require Net::Async::Gearman::Client;
require Net::Async::Gearman::Worker;

pass( 'Modules loaded' );
done_testing;
