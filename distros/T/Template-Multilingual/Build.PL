use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::Multilingual',
    license             => 'perl',
    dist_author         => 'Eric Cholet <cholet@logilune.com>',
    dist_version_from   => 'lib/Template/Multilingual.pm',
    requires => {
        'Test::More' => 0,
        'Template'   => 2,
    },
    add_to_cleanup      => [ 'Template-Multilingual-*' ],
);

$builder->create_build_script();
