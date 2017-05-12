use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'News::Pictures',
    license             => 'perl',
    dist_author         => 'Christian Guine <c.guine@free.fr>',
    dist_version_from   => 'lib/News/Pictures.pm',
    dist_abstract       => 'a package which allows to search photographs in a forum, to show them and possibly to save them',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'News-Pictures-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();