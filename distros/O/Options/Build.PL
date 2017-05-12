use Module::Build;
my $build = Module::Build->new(
   module_name => 'Options',
   license  => 'perl',
   requires => {
                'perl'          => '5.6.1'
               },
   recommends => {
                'perl'                => '5.8',
                'Test::More'          => 0,
                'Test::Pod::Coverage' => 0,
                'Test::Pod'           => '>= 1.0',
                'Test::Unit'          => '>= 0.25'
               },
   create_makefile_pl => 'traditional'
);
$build->create_build_script;