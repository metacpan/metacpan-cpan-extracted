use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Model::Envoy::Storage::Redis',
    license           => 'MIT',
    dist_author       => 'Stephen Howard <stephen@enterity.com>',
    dist_version_from => 'lib/Model/Envoy/Storage/Redis.pm',
    dist_abstract     => 'A Model::Envoy plugin for peristing model information in a Redis store.',
    requires    => {
        'perl'                   => '5.18.2',
        'Moose'                  => '>= 2.2010',
        'Model::Envoy'           => '>= 0.5.3',
        'Redis::Fast'            => '>= 0.21',
        'MooseX::ClassAttribute' => '>=0.29',
        'JSON::XS'               => '>=3.04',
    },
    configure_requires => {
        'Module::Build' => '>= 0.4211',
    },
    test_requires    => {
        'Test::More' => '>= 1.302085',
    },
)->create_build_script;
