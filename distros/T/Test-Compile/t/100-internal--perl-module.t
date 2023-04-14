#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

# given
# when
my $taint = $internal->_perl_module('t/scripts/taint.pl');
# then
ok(!$taint, "taint.pl script is not a module");

# Given
# When
my $datafile = $internal->_perl_module('t/scripts/datafile');
# Then
ok(!$datafile, "datafile isn't perl");

# Given
# When
my $perlscript = $internal->_perl_module('t/scripts/perlscript');
ok(!$perlscript, "perlscript is not a module");

# Given
# When
my $module = $internal->_perl_module('t/scripts/Module.pm');
ok($module, "Module.pm is a module");

done_testing();
