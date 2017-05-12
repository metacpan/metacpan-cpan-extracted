use Module::Build;
my $build = new Module::Build
(
  module_name    => 'Template::Plugin::ListUtil',
  license        => 'perl',
  requires       => {
                       'List::Util' => 0,
                       'Template'   => "2.06", # this late for T::P::Proc
                       'Template::Plugin::VMethods' => "0.02",
                    },
  recommends     => {
                    },
  build_requires => {
                       'Test::More' => 0
                    },
 create_makefile_pl => 'traditional',

);
$build->create_build_script;
