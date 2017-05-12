# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::IP::Route::Reject' ); }

 Net::IP::Route::Reject->add ('1.1.1.1');#pass if it doesn't blow up
#isa_ok ($object, 'Net::IP::Route::Reject');
Net::IP::Route::Reject->del('1.1.1.1');
pass("Add/Delete route 1.1.1.1");


