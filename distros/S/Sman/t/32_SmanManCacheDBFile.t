# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test::More tests => 2;

# we don't use the DB_File cache anymore
#use Sman::Man::Cache::DB_File; 
ok(1); # If we made it this far, we're ok.


# we don't use the DB_File cache anymore
#my $obj = new Sman::Man::Cache::DB_File(undef); 
ok(1); # If we made it this far, we're ok.  


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

