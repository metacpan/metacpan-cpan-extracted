use strict;
use warnings;
use Test::More;
plan skip_all => 'Moose and MooseX::Getopt required to test Moose usage'
    if not eval { require Moose; require MooseX::Getopt; 1 }
    or $@;
plan tests => 2;

use lib 't/lib';
use_ok('Test::MyAny::Moose');
my $cmd = new_ok('Test::MyAny::Moose');
