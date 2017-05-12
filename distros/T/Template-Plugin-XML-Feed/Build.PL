use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Template::Plugin::XML::Feed',
  dist_version       => '0.03',
  license            => 'perl',
  create_makefile_pl => 'traditional',
  requires           => {
    Template => 0,
    XML::Feed => 0,
  },
  build_requires     => {
    Test::More => 0,
  },
  build_recommends   => {
    Test::Pod           => 0,
    Test::Pod::Coverage => 0,
  },
);

$build->create_build_script;
