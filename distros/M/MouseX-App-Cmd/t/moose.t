#!perl -T

use strict;
use warnings;
use Test::More;
plan skip_all => 'Mouse and MouseX::Getopt required to test Mouse usage'
    if not eval { require Mouse; require MouseX::Getopt; 1 }
    or $@;
plan tests => 2;

use lib 't/lib';
use_ok('Test::MyAny::Mouse');
my $cmd = new_ok('Test::MyAny::Mouse');
