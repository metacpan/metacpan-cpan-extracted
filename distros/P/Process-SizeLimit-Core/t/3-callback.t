#! /usr/bin/env perl

use strict;
use warnings;
use Test::More 0.31;

#plan skip_all => 'Not on linux' unless $^O eq 'linux';

use_ok('Process::SizeLimit::Core');

my @log;

Process::SizeLimit::Core->set_callback( sub { push @log, [@_] } );

my ($size, $share, $unshared) = Process::SizeLimit::Core->_check_size();

cmp_ok $size,     '>',  0, "size > 0 ($size)";
cmp_ok $share,    '>=', 0, "share > 0 ($share)";
cmp_ok $unshared, '>',  0, "unshared > 0 ($unshared)";
is $unshared, $size - $share, "unshared = size - share";

is_deeply \@log, [ [ $size, $share, $unshared ] ], 'callback';

done_testing;
