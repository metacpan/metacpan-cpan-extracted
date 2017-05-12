# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-SVN-AutoCommit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 4;
BEGIN { use_ok('Sorauta::SVN::AutoCommit') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use_ok('SVN::Agent');
use_ok('Image::Magick');

my $ssa = Sorauta::SVN::AutoCommit->new;
ok($ssa, "create new instance");

# commit test
=pod
{
  my $SVN_MODE = "auto_commit";
  my $SVN_WORK_DIR = "/Users/user/Desktop/svn_dir";
  my $DEBUG = 0;

  my $ssa = Sorauta::SVN::AutoCommit->new({
    svn_mode      => $SVN_MODE,
    work_dir_path => $SVN_WORK_DIR,
    debug         => $DEBUG,
  });

  print $ssa;
  $ssa->execute();
}
=cut

1;
