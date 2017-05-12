use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Template::Plugin::VMethods',
  license        => 'perl',
  requires       => {
		      'Template'  => 2.06,
                    },
  recommends     => {
                    },
  build_requires => {
		      'Test::More' => 0,
                    },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
