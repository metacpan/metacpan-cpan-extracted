use Module::Build;

my $build_pkg = eval { require Apache::TestMB }
? 'Apache::TestMB' : 'Module::Build';

my $build = $build_pkg->new
(
    module_name => 'Sleep',
    license     => 'perl',
    build_requires     => { Apache::Test => '1.12' },

    requires    => {
        'JSON::XS'   => 0,
        Carp         => 0,
        'DBIx::DWIW' => '0.48',
    },
);
$build->create_build_script;
