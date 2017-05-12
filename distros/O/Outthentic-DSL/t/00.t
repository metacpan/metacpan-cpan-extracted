
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Outthentic::DSL') };
my $dsl = Outthentic::DSL->new({ output => 'hello'});

isa_ok($dsl,'Outthentic::DSL');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

