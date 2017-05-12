
use Module::Build;
my $build = Module::Build->new(
  module_name => 'SCGI',
  dist_abstract => 'SCGI server library for perl',
  create_makefile_pl => 'passthrough',
  license => 'perl',
  requires => {
    'perl' => '5.8.0',
  },
);
$build->create_build_script;
