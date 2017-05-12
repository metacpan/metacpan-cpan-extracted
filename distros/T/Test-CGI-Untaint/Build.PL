use Module::Build;
my $build = new Module::Build
(
  module_name        => 'Test::CGI::Untaint',
  license            => 'perl',
  requires           => {
			 "Test::Builder" => 0,
                         "CGI::Untaint" => 0.82,
                         },
  recommends         => {
                        },
  build_requires     => {
                          "Test::Builder::Tester" => 0.09,
                        },
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
