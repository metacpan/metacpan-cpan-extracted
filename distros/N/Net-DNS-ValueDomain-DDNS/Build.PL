use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Net::DNS::ValueDomain::DDNS',
    license     => 'perl',
    requires    => {
        Readonly                => 0,
        'LWP::UserAgent'        => 0,
        'Class::Accessor::Fast' => 0,
        'Class::ErrorHandler'   => 0,
        'HTTP::Request::Common' => 0,
    },
    recommends     => { 'Crypt::SSLeay' => 0, },
    build_requires => {
        'Test::More'       => 0,
        'Test::MockObject' => 0,
    },
)->create_build_script;
