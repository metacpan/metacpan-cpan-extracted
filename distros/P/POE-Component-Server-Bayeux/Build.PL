use Module::Build;

my $build = Module::Build->new(
    module_name => 'POE::Component::Server::Bayeux',
    license => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP' => 0,
        'Params::Validate' => 0,
        'POE::Component::Client::HTTP' => 0,
        'POE::Component::Server::HTTP' => '0.09',
        'Class::Accessor' => 0,
        'Log::Log4perl' => 0,
        'URI' => 0,
        'JSON::Any' => 0,
        'JSON::XS' => 0,
        'Switch' => 0,
        'Data::UUID' => 0,
        'CGI::Simple' => 0,
    },
    sign => 1,
    create_makefile_pl => 'passthrough',
    create_readme => 1,
);

$build->create_build_script;
