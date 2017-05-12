use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Shell::Parser',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Shell/Parser.pm',
    requires => {
        'Carp' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Shell-Parser-*' ],
);

$builder->create_build_script();
