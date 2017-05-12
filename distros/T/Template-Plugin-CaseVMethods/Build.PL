use Module::Build;
my $build = new Module::Build
(
  module_name        => 'Template::Plugin::CaseVMethods',
  license            => 'perl',
  requires           => {
			 'Template::Plugin::VMethods' => 0,
                        },
  recommends         => {
                        },
  build_requires     => {
			 'Test::More' => 0,
                        },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
