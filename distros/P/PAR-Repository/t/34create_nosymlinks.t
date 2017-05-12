use strict;
use warnings;
use Test::More tests => 39;
BEGIN { $ENV{PAR_REPOSITORY_SYMLINK_SUPPORT} = 0 }
BEGIN { use_ok('PAR::Repository') };

chdir('t') if -d 't';
use lib 'lib';
# requires 3 tests to boot
require RepoTest;
#$RepoTest::Debug = 1;

my $tdir = RepoTest->TempDir;
my $repodir = File::Spec->catdir($tdir, 'repo');

chdir($tdir);

# test plain create
ok(!RepoTest->RunParrepo('create'), 'parrepo create did not die');
ok(-d $repodir, 'parrepo create created a repo dir');
ok(RepoTest->CanOpenRepo($repodir), 'can open repo with PAR::Repository');
RepoTest->TestRepoFilesExist($repodir);

# test named create
$repodir = File::Spec->catdir($tdir, 'otherrepo');
ok(!RepoTest->RunParrepo('create', '-r', 'otherrepo'), 'parrepo create otherrepo did not die');
ok(-d $repodir, 'parrepo create otherrepo created another repo dir');
ok(RepoTest->CanOpenRepo($repodir), 'can open repo with PAR::Repository');
RepoTest->TestRepoFilesExist($repodir);

# test module-based auto-create
$repodir = File::Spec->catdir($tdir, 'norepo');
ok(!-d $repodir, 'norepo doesnt exist yet');
ok(RepoTest->CanOpenRepo($repodir), 'can open and auto-create repo with PAR::Repository');
RepoTest->TestRepoFilesExist($repodir);

