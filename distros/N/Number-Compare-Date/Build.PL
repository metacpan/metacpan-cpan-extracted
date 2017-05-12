use Module::Build;
my $build = new Module::Build
(
  module_name        => 'Number::Compare::Date',
  license            => 'perl',
  requires           => {
			  'Number::Compare' => "0.01",
                          'Date::Parse'     => "2.27",
                         },
  recommends         => {
                        },
  build_requires     => {
			  'Test::More' => 0,
                        },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
