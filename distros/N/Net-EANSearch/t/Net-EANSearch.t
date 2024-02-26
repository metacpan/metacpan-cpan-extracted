# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-EANSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
BEGIN { use_ok('Net::EANSearch') };

#########################

my $eansearch = Net::EANSearch->new('invalid-token');
ok(defined($eansearch));

