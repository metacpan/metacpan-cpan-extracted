# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Box.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Regexp::Box') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

  my $rebox = Regexp::Box->new();

    $rebox->request( 'db/mysql/date', 'regexp' );

    $rebox->request( 'db/mysql/datetime', 'regexp' );

    $rebox->request( 'db/mysql/timestamp', 'regexp' );

    $rebox->request( 'db/mysql/time', 'regexp' );
 
    $rebox->request( 'db/mysql/year4', 'regexp' );

    $rebox->request( 'db/mysql/year2', 'regexp' );
