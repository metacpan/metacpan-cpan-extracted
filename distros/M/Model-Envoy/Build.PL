use Module::Build;

my $build = Module::Build->new(
    module_name => 'Model::Envoy',
    license     => 'MIT',
    dist_author       => 'Stephen Howard <stephen@enterity.com>',
    dist_version_from => 'lib/Model/Envoy.pm',
    dist_abstract     => 'A Moose Role that can be used to build a model layer that keeps business logic separate from your storage layer.',
    requires    => {
        'perl'        => '5.18.2',
        'Moose'       => '>= 2.2010',
        'DBIx::Class' => '>= 0.082840',
    },
    configure_requires => {
      'Module::Build' => '>= 0.4211',
    },
    test_requires    => {
        'Test::More'        => '>= 1.302085',
        'Test::Exception'   => '>= 0.43',
    },
)->create_build_script;