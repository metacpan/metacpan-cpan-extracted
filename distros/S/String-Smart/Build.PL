use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name       => 'String::Smart',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/String/Smart.pm',
  requires          => {
    'Test::More'   => 0,
    'Scalar::Util' => 0,
  },
  add_to_cleanup => ['String-Smart-*'],
);

$builder->create_build_script();
