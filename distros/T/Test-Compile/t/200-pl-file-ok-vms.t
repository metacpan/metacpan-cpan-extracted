#!perl -w
use strict;
use warnings;
use Test::More;
use Test::Compile qw( pl_file_ok );

plan skip_all => 'No Devel::CheckOS, skipping'
    unless Devel::CheckOS->require;
plan tests => 1;

# cheap emulation
$^O = 'VMS';

pl_file_ok('t/scripts/subdir/success.pl', 'success.pl compiles');
