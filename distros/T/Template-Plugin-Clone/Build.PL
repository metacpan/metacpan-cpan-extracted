use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Template::Plugin::Clone',
  license        => 'perl',
  requires       => {
                      'Template::Plugin::VMethods' => 2.06,
                      'Template' => 2,
                    },
  recommends     => {
                    },
  build_requires => {
		      'Test::More' => 0,
                    },
 create_makefile_pl => 'traditional',
);
$build->create_build_script;
