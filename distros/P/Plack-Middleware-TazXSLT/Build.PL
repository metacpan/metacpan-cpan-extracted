use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
    'build_requires'     => { 'Module::Build' => '0.4004' },
    'configure_requires' => { 'Module::Build' => '0.4004' },
    'license'            => 'perl',
    'module_name'        => 'Plack::Middleware::TazXSLT',
    'meta_merge'         => {
        resources =>
          { repository => 'https://github.com/mdom/Plack-Middleware-TazXSLT' }
    },
    'requires' => {
        'Capture::Tiny'       => '0',
        'LWP::UserAgent'      => '0',
        'Plack::Request'      => '0',
        'Plack::Response'     => '0',
        'Plack::Util'         => '0',
        'Plack::Middleware'   => '0',
        'Try::Tiny'           => '0',
        'XML::LibXML'         => '0',
        'XML::LibXSLT'        => '1.72',
        'URI::QueryParam'     => '0',
        'HTTP::Response'      => '0',
        'HTTP::Message::PSGI' => '0',
        'parent'              => '0',
    },
    test_requires => {
        'Test::More'                => '0',
        'Test::MockObject::Extends' => '0',
        'HTTP::Request'             => '0',
        'Carp'                      => '0',
    },
);

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;

