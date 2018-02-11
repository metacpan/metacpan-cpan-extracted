#!perl

package Net::Statsd::Lite::Test::Class;

use Test::Roo;

use lib 't/lib';
with qw/ Net::Statsd::Lite::Test Test::Roo::DataDriven /;

1;

package main;

use strict;
use warnings;

use Devel::StrictMode;

use Test::More;
use if STRICT, "Test::Warnings";

Net::Statsd::Lite::Test::Class->run_data_tests( files => 't/data', );

done_testing;
