# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Net::LibNIDS') };
use strict;

###my $fail = 0;
#foreach my $constname (qw(
#	NIDS_CLOSE NIDS_DATA NIDS_EXITING NIDS_JUST_EST NIDS_MAJOR NIDS_MINOR
#	NIDS_RESET NIDS_TIMED_OUT)) {
#  print Net::LibNIDS->$constname() . "\n";


#}


Net::LibNIDS::param::set_device('en66');
is(Net::LibNIDS::param::get_device(), 'en66', "Device setting works");

