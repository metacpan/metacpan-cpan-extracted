
use strict;
use warnings;

use Test::More;
use FindBin;

use Path::FindDev qw(find_dev);
use Path::Tiny qw(path);

sub cmp_paths {
  my ( $search, $real ) = @_;
  my $searched = find_dev($search);
  return unless ok( $searched, 'find_dev returned something' );
  $searched = $searched->absolute->stringify;
  my $realed = path($real)->absolute->stringify;
  is( $searched, $realed, 'found and expected match' );
}

plan tests => ( $ENV{SYSTEM_PATH_TEST} ? 3 : 2 );
cmp_paths( $FindBin::Bin, path($FindBin::Bin)->parent );

if ( $ENV{SYSTEM_PATH_TEST} ) {
  my $t_dir = path($FindBin::Bin);

  my $source_root = $t_dir->parent;

  my $outside_path = $source_root->parent;    # PROJECT_ROOT/../

  # if _THIS_ file is stored at  SOMEPATH/Path-FindDev/.build/randomletters/t/basic.t
  # then instead of doing tree traversal from
  #   SOMEPATH/Path-FindDev/.build/randomletters/
  # do it from
  #   SOMEPATH
  #
  # More annoying, during dzil release testing, the path is
  # is stored at  SOMEPATH/Path-FindDev/.build/randomletters/Path-IsDev-0.4/t/basic.t

  if ( $outside_path->basename eq '.build' ) {
    $outside_path = $outside_path->parent->parent;
  }
  elsif ( $outside_path->parent->basename eq '.build' ) {
    $outside_path = $outside_path->parent->parent->parent;
  }

  diag "External search started at " . $outside_path;

  if ( not is( find_dev($outside_path), undef, 'Finding a dev directory above the project directory should miss' ) ) {
    no warnings 'once';
    local $Path::IsDev::Object::DEBUG   = 1;
    local $Path::FindDev::Object::DEBUG = 1;
    diag "As the previous test failed, debug diagnosics for Path::IsDev are being turned on";
    diag "These will hopefully tell you what warts your filesystem has that results in false-postives for dev dirs";

    find_dev($outside_path);
  }
}
else {
  diag "System path sanity check skipped due to potential security risks, set ENV{SYSTEM_PATH_TEST} if you wish to run this test";
}
