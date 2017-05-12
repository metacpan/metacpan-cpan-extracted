# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 2 ;

BEGIN { use_ok('Numeric::LL_Array') };

my ($tn, $ts) = (Numeric::LL_Array::typeNames(), Numeric::LL_Array::typeSizes());
warn "Unexpected code in tn=`$tn'\n" . Numeric::LL_Array::db_win32()
 if $tn =~ /[^a-zA-Z]/;
ok(!($tn =~ /[^a-zA-Z]/), 'used type codes are characters');