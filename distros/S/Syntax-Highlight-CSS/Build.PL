use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Syntax::Highlight::CSS',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/Syntax/Highlight/CSS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'Syntax-Highlight-CSS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
