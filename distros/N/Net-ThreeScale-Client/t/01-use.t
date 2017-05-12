use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More  tests=>2;

use_ok('Net::ThreeScale::Client');
use_ok('Net::ThreeScale::Response');
