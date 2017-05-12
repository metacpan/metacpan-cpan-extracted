use strict;
use warnings;
use Module::Build 0.3601;

my %module_build_args = (
    'license'     => 'perl',
    'module_name' => 'Plack::Middleware::Proxy::ByHeader',
    'requires'    => {
        'Plack::Request'        => 0,
        'Plack::Util::Accessor' => 0,
        'Plack::Middleware'     => 0,
        'Carp'                  => 0,
    },
    'test_requires' => {
        'Plack::Test'           => 0,
        'Test::More'            => 0,
        'HTTP::Request::Common' => 0,
        'Plack::Builder'        => 0,
        'URI'                   => 0,
    },
);

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;

