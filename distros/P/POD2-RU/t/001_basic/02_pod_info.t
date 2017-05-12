#########################
# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use utf8;

use Test::More tests => 1;
#use Test::More::UTF8;
#use Test::Deep;
use POD2::RU;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $pod2 = POD2::RU->new();
#use Data::Dumper;
like($pod2->pod_info(), qr/\Q5.18.0.1\E/, '5.18.0.1');

