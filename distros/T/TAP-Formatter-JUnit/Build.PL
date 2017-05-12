use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'TAP::Formatter::JUnit',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'requires'          => {
        'XML::Generator'    => 0,
        'TAP::Harness'      => 3.12,
        'Moose'             => 0,
        'MooseX::NonMoose'  => 0,
        'File::Slurp'       => 0,
        },
    'build_requires'    => {
        'Test::More'        => 0,
        'IO::Scalar'        => 0,
        'IPC::Run'          => 0,
        'Test::XML'         => 0,
        },
    )->create_build_script();
