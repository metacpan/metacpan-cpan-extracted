use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Syntax::Highlight::Shell',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Syntax/Highlight/Shell.pm',
    requires => {
        'Shell::Parser' => '0.02',
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Syntax-Highlight-Shell-*' ],
);

$builder->create_build_script();
