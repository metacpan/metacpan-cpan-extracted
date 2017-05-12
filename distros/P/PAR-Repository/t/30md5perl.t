use strict;
use warnings;
BEGIN {
  # only run these tests if Digest::Perl::MD5 is installed
  require Test::More;
  eval {require Digest::Perl::MD5;};
  if ($@) {
    Test::More->import( skip_all => 'Requiring Digest::Perl::MD5 for this test' );
    exit();
  }
  else {
    Test::More->import( tests => 1+3+13 );
    delete $INC{'Digest/MD5/Perl.pm'};
  }
}
# mwuahaha!
BEGIN {unshift @INC, sub {if ($_[1] eq 'Digest/MD5.pm') {my @l = ('package Digest::MD5; 0;');return sub {shift(@l)||0}}}}
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
my $repo = RepoTest->CanOpenRepo($repodir);
ok($repo, 'can open repo with PAR::Repository');
RepoTest->TestRepoFilesExist($repodir);
$repo->DESTROY();
ok(1, 'still alive after cleanup of repo');


