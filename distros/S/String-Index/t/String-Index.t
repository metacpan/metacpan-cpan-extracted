# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl String-Index.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 37;
BEGIN { use_ok('String::Index', qw( cindex ncindex crindex ncrindex )) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# tests that don't use nulls
#

ok( cindex(  "japhy", "aeiouy"   ) == 1 );
ok( cindex(  "japhy", "aeiouy", 1) == 1 );
ok( cindex(  "japhy", "aeiouy", 2) == 4 );

ok( ncindex( "japhy", "aeiouy"   ) == 0 );
ok( ncindex( "japhy", "aeiouy", 1) == 2 );
ok( ncindex( "japhy", "aeiouy", 2) == 2 );

ok( crindex( "japhy", "aeiouy"   ) == 4 );
ok( crindex( "japhy", "aeiouy", 1) == 1 );
ok( crindex( "japhy", "aeiouy", 2) == 1 );

ok( ncrindex("japhy", "aeiouy"   ) == 3 );
ok( ncrindex("japhy", "aeiouy", 1) == 0 );
ok( ncrindex("japhy", "aeiouy", 2) == 2 );


#
# tests that use nulls
#

ok( cindex(  "jap\0hy", "aei\0ouy"   ) == 1 );
ok( cindex(  "jap\0hy", "aei\0ouy", 1) == 1 );
ok( cindex(  "jap\0hy", "aei\0ouy", 2) == 3 );

ok( ncindex( "jap\0hy", "aei\0ouy"   ) == 0 );
ok( ncindex( "jap\0hy", "aei\0ouy", 1) == 2 );
ok( ncindex( "jap\0hy", "aei\0ouy", 2) == 2 );

ok( crindex( "jap\0hy", "aei\0ouy"   ) == 5 );
ok( crindex( "jap\0hy", "aei\0ouy", 1) == 1 );
ok( crindex( "jap\0hy", "aei\0ouy", 2) == 1 );

ok( ncrindex("jap\0hy", "aei\0ouy"   ) == 4 );
ok( ncrindex("jap\0hy", "aei\0ouy", 1) == 0 );
ok( ncrindex("jap\0hy", "aei\0ouy", 2) == 2 );


#
# tests that return -1
#

ok( cindex(  "japhy", uc "aeiouy"   ) == -1 );
ok( cindex(  "japhy", uc "aeiouy", 1) == -1 );
ok( cindex(  "japhy", uc "aeiouy", 2) == -1 );

ok( ncindex( "japhy", "japhy"       ) == -1 );
ok( ncindex( "japhy", "japhy",     1) == -1 );
ok( ncindex( "japhy", "japhy",     2) == -1 );

ok( crindex( "japhy", uc "aeiouy"   ) == -1 );
ok( crindex( "japhy", uc "aeiouy", 1) == -1 );
ok( crindex( "japhy", uc "aeiouy", 2) == -1 );

ok( ncrindex("japhy", "japhy"       ) == -1 );
ok( ncrindex("japhy", "japhy",     1) == -1 );
ok( ncrindex("japhy", "japhy",     2) == -1 );

