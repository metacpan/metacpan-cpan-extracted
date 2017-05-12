# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Perl-AfterFork.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;

my $parent;
my $pparent;
my $pid;

BEGIN {
  require 'syscall.ph';

  $|=1;

  $parent=$$;
  $pparent=getppid;

  print "# parent=$parent, pparent=$pparent\n";

  $pid=syscall( &SYS_fork );

  die "fork(2): $!\n" if( $pid<0 );

  if( $pid ) {
    waitpid $pid, 0;
    exit 0;
  }
}

use Test::More tests => 5;
use Perl::AfterFork ();

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok $$==$parent, '$$ has not changed over fork';
ok getppid==$pparent, 'getppid has not changed over fork';

ok Perl::AfterFork::reinit, 'reinit_pid';
ok $$!=$parent, '$$ has changed after reinit_pid';
ok getppid==$parent, 'getppid has changed after reinit_ppid';

## Local Variables: ##
## mode: cperl ##
## End: ##
