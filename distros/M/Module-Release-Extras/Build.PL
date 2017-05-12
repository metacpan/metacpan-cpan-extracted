use Module::Build;
my $build = new Module::Build
(
  module_name        => 'Module::Release::Extras',
  license            => 'perl',
  requires           => {
			 'Module::Release' => '0.23',
			 'URI'		   => '1.30',
                         },
  recommends         => {
                        },
  build_requires     => {
                        },
);
$build->create_build_script;
