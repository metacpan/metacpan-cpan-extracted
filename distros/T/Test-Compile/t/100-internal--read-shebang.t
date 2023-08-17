#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();
my $perl;

# Given: a file without a shebang
# When: call _read_shebang()
$perl = $internal->_read_shebang('t/scripts/datafile');
# Then
ok(!$perl, "The datafile doesn't look like a perl program");

# Given: a file with a perl shebang
# When: call _read_shebang()
$perl = $internal->_read_shebang('t/scripts/perlscript');
# Then
ok($perl, "The perlscript does look like a perl program");

# Given: a file that can't be read..
# When: call _read_shebang()
$perl = $internal->_read_shebang('t/scripts/i-dont-exist');
# Then: Gotta assume it's not perl
ok(!$perl, "if you can't read a file, then it's not perl");

$internal->done_testing

