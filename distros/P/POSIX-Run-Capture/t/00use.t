# -*- perl -*-
#########################

use strict;
use warnings;

use Test::More  tests => 3;
BEGIN { use POSIX::Run::Capture };

ok(eval { new POSIX::Run::Capture(['cat', 'file']) });
ok(eval { new POSIX::Run::Capture(argv => ['cat', 'file'], timeout => 3) });
ok(!eval { new POSIX::Run::Capture(1, 2) });
       
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

