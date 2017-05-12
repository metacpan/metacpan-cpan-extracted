use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'Search::Mousse',
  requires           => {
    'CDB_File'                       => '0',
    'Class::Accessor::Chained::Fast' => '0',
    'Cwd'                            => '0',
    'List::Uniq'                     => '0',
    'MealMaster'                     => '0',
    'Path::Class'                    => '0',
    'Set::Scalar'                    => '0',
    'Search::QueryParser'            => '0',
    'Search::ContextGraph'           => '0',
    'Storable'                       => '0',
    'Test::Exception'                => '0',
    'Test::More'                     => '0',
    'Text::Soundex'                  => '0',
  },
);
$build->create_build_script;
