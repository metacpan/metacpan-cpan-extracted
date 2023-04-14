#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

# given
# when
my $taint = $internal->_perl_script('t/scripts/taint.pl');
# then
ok($taint, "taint.pl script is perll");

# Given
# When
my $datafile = $internal->_perl_script('t/scripts/datafile');
# Then
ok(!$datafile, "datafile isn't perl");

# Given
# When
my $perlscript = $internal->_perl_script('t/scripts/perlscript');
ok($perlscript, "perlscript is perl");

# Given
# When
my $module = $internal->_perl_script('t/scripts/Module.pm');
ok(!$module, "Module is not a script");

done_testing();
