# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Box.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Regexp::Box') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use IO::Extended ':all';

$Regexp::Box::DEBUG = 0;

  my $rebox = Regexp::Box->new();

  $rebox->request( 'std/word', 'regexp' );

  $rebox->request( 'std/binary', 'regexp' );
     
  $rebox->request( 'std/hex', 'regexp' );

  $rebox->request( 'std/int', 'regexp' );
     
  $rebox->request( 'std/real', 'regexp' );
     
  $rebox->request( 'std/quoted', 'regexp' );
     
  println $rebox->request( 'std/uri', 'regexp' );  
     
  println $rebox->request( 'std/net', 'regexp' ); 
     
  $rebox->request( 'std/zip', 'regexp' );
     
  $rebox->request( 'std/domain', 'regexp' );
 

  println $_ for sort $rebox->requestable;