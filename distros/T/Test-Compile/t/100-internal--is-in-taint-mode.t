#!perl

use strict;
use warnings;

use Test::More;
use Test::Compile::Internal;

my $internal = Test::Compile::Internal->new();

my $TAINT = $internal->_is_in_taint_mode('t/scripts/taint.pl');
is($TAINT,"T","Found taint flag in taint.pl");

my $taint = $internal->_is_in_taint_mode('t/scripts/CVS/taint2.pl');
is($taint,"t","Found taint warning flag in taint2.pl");

my $not = $internal->_is_in_taint_mode('t/scripts/subdir/success.pl');
is($not,"","No taint flags found in success.pl");

done_testing();
