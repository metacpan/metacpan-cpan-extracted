use Module::Build;

use lib 'inc';
use MyBuilder;

my $build = MyBuilder->new(
  module_name       => 'Path::Class::Each',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Path/Class/Each.pm',
  requires          => {
    'Test::More'       => 0,
    'Path::Class' => '0.18',
  },
  PL_files       => {},
  add_to_cleanup => ['Path-Class-Each-*'],
  sign           => 1,
  license        => 'perl',
  create_readme  => 1,
);

$build->create_build_script;
