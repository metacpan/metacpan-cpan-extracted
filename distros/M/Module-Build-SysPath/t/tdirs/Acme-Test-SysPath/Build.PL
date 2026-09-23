use strict;
use warnings;
use Module::Build::SysPath;

my $builder = Module::Build::SysPath->new(
    module_name => 'Acme::Test::SysPath',
    license     => 'perl',
    configure_requires => {
        'Module::Build::SysPath' => 0.09,
    },
    build_requires => {
    },
    requires => {
    },
    conffiles => [
        [ 'share', 'share' ],
    ],
);

$builder->create_build_script();
