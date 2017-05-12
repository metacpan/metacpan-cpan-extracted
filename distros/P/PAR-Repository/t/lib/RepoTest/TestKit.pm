package RepoTest::TestKit;
use strict;
use warnings;

require Test::More;
require File::Spec;

####################
sub check_injection {
  my $class = shift;
  my $files = shift;
  die if not defined $files;
  $files = [$files] if not ref($files);
  my $repodir = shift || File::Spec->catdir(RepoTest->TempDir, 'repo');

  foreach my $file (@$files) {
    my ($dn, $dv, $arch, $pv) = PAR::Dist::parse_dist_name($file);
    Test::More::ok(
      -e File::Spec->catfile($repodir, $arch, $pv, $file),
      "par '$file' was injected"
    );
  }

  # test whether the stuff is in the repository now
  my $repo = RepoTest->CanOpenRepo($repodir);
  my $result = {@{$repo->query_module(regex => '^Test::Kit$')}};
  my $expect = {map {($_, '0.02')} @$files};
  Test::More::is_deeply(
    $result, $expect
  );
  #use Data::Dumper; warn Dumper $result;
  #use Data::Dumper; warn Dumper $expect;

  $result = {@{$repo->query_dist(regex => '^Test-Kit')}};
  $expect = {map {($_,
      {
        'Test::Kit' => '0.02',
        'Test::Kit::Result' => '0.02',
        'Test::Kit::Features' => '0.02',
      },
      )} @$files
  };
  Test::More::is_deeply(
    $result, $expect, 'provides matches'
  );

}

####################
sub check_symlinks {
  my $class = shift;
  my $symlinks = shift || {};
  my $repodir = shift || File::Spec->catdir(RepoTest->TempDir, 'repo');

  my $repo = RepoTest->CanOpenRepo($repodir);

  my ($dbm) = $repo->symlinks_dbm();
  my $copy = tied(%$dbm)->export(); # don't do this at home;
  Test::More::is_deeply(
    $copy,
    $symlinks,
    'symlinks match'
  );
}

####################
sub check_dependencies {
  my $class = shift;
  my $deps  = shift || {};
  my $repodir = shift || File::Spec->catdir(RepoTest->TempDir, 'repo');

  my $repo = RepoTest->CanOpenRepo($repodir);

  my ($dbm) = $repo->dependencies_dbm();
  my $copy = tied(%$dbm)->export(); # don't do this at home;
  Test::More::is_deeply(
    $copy,
    $deps,
    'dependencies match'
  );
}


####################
sub check_removal {
  my $class = shift;
  my $file = shift;
  die if not defined $file;
  my $repodir = shift || File::Spec->catdir(RepoTest->TempDir, 'repo');

  my ($dn, $dv, $arch, $pv) = PAR::Dist::parse_dist_name($file);

  my $repo = RepoTest->CanOpenRepo($repodir);
  Test::More::ok(
    !-f File::Spec->catfile($repodir, $arch, $pv, $file),
    'par was removed'
  );
  Test::More::is_deeply(
    $repo->query_module(regex => '^Test::Kit$'),
    [],
  );
  Test::More::is_deeply(
    $repo->query_dist(regex => '^Test-Kit'),
    []
  );
}

1;

