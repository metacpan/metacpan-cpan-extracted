# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-SVN-Updater.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 3;
BEGIN { use_ok('Sorauta::SVN::Updater') };

use_ok('SVN::Agent');
use_ok('File::Copy::Recursive');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

=pod
my $WORK_DIR_PATH = '/Users/user/Desktop/hogehoge';
my $OS = "Mac"; # or Win
my $REPOSITORY_URL = 'http://svn_url/path/to';
my $TMP_DIR_PATH = '/Users/user/Desktop/hogehoge_tmp';
my $DEBUG = 1;

# svn update test
{
  my $res = Sorauta::SVN::Updater->new({
    os                    => $OS,
    repository_url        => $REPOSITORY_URL,
    work_dir_path         => $WORK_DIR_PATH,
    tmp_dir_path          => $TMP_DIR_PATH,
    debug                 => $DEBUG,

  })->execute;

  ok($res, "svn update test");
}
=cut

1;
