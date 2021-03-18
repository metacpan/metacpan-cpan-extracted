use strict;
use warnings;
use Test::More;
plan tests => 2;

use lib 't/lib';
use_ok('Test::MyAny::Moose');
my $cmd = new_ok('Test::MyAny::Moose');
