#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;

#plan skip_all => 'Not on linux' unless $^O eq 'linux';

use_ok('Process::SizeLimit::Core');

my ($size, $share, $unshared) = Process::SizeLimit::Core->_check_size();
cmp_ok $size,     '>',  0, "size > 0 ($size)";
cmp_ok $share,    '>=', 0, "share > 0 ($share)";
cmp_ok $unshared, '>',  0, "unshared > 0 ($unshared)";
is $unshared, $size - $share, "unshared = size - share";

no warnings qw(uninitialized);
diag sprintf "USE_SMAPS=%s", do { no warnings qw(once); $Process::SizeLimit::Core::USE_SMAPS; };

# more tests needed!

done_testing;
