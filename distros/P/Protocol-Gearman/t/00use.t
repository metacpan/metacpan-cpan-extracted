#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

require Protocol::Gearman;
require Protocol::Gearman::Client;
require Protocol::Gearman::Worker;
require Net::Gearman;
require Net::Gearman::Client;
require Net::Gearman::Worker;

pass( 'Modules loaded' );
done_testing;
