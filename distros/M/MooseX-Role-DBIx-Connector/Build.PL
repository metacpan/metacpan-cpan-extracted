use Module::Build;
my $build = Module::Build->new(
    module_name          => 'MooseX::Role::DBIx::Connector',
    dist_name            => 'MooseX-Role-DBIx-Connector',
    dist_abstract        => 'Generic Moose parameterized role to give your class DBIx::Connector powers',
    license              => 'perl',
    recursive_test_files => 1,
    create_readme        => 1,
    create_license       => 1,
    meta_merge           => {
        resources =>
          { repository => 'http://github.com/rbuels/MooseX-Role-DBIx-Connector', },
    },
    build_requires => { 
        'Test::Exception' => '0.27',
        'Moose'           => 0,
    },
    requires       => {
        'perl' => '5.8.0',

        'DBIx::Connector'             => 0,
        'MooseX::Role::Parameterized' => 0,

    },
);
$build->create_build_script;
