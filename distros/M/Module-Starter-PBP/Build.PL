use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Starter::PBP',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Module/Starter/PBP.pm',
    requires => {
        'Test::More'      => 0,
        'Module::Starter' => 0,
        'version'         => 0,
    },
    add_to_cleanup      => [ 'Module-Starter-PBP-*' ],
);

$builder->create_build_script();
