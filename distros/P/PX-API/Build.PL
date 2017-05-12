use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'PX::API',
    license             => 'perl',
    dist_author         => 'Anthony Decena <anthony@1bci.com>',
    dist_version_from   => 'lib/PX/API.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'PX-API-*' ],
);

$builder->create_build_script();
