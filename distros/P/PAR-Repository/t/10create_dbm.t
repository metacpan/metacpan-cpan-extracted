use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok('PAR::Repository') };

chdir('t') if -d 't';
use lib 'lib';
# requires 3 tests to boot
require RepoTest;
#$RepoTest::Debug = 1;

my $tdir = RepoTest->TempDir;
my $repodir = File::Spec->catdir($tdir, 'repo');

chdir($tdir);

my $mock = bless {} => 'PAR::Repository';
can_ok($mock, '_create_dbm');
my $dbmfile = 'foo.zip';
ok( $mock->_create_dbm($dbmfile) );
ok( -f $dbmfile );
unlink($dbmfile);
bless $mock => 'DOESNOTEXIST';


