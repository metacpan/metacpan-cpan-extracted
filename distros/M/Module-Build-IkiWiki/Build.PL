use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Build::IkiWiki',
    license             => 'gpl',
    dist_author         => '"Víctor Moral" <victor@taquiones.net>',
    dist_version        => '0.0.6',
    requires => {
        'Test::More'        => 0,
        'Module::Build'     =>  '>= 0.26',
    },
    recommends  =>  {
        'Test::Pod'             =>  '>= 1.14',
        'Test::Pod::Coverage'   =>  '>= 1.04',
        'Test::Perl::Critic'    =>  0,
    },
    add_to_cleanup      => [ 
                'Module-Build-IkiWiki-*',
                'libmodule-build-ikiwiki-perl*'
    ],
    script_files        =>  {
        'scripts/pod2mdwn'  =>  '',
    },
    create_packlist     =>  0,
    installdirs         =>  q(vendor),
    meta_merge          =>  {
        resources   =>  {
            homepage    =>  q(http://taquiones.net/software/factory/module-build-ikiwiki.html),
        },
    },
    meta_add            =>  {
        no_index        =>  {
            directory   =>  [ qw(t/lib examples) ],
        },
    },
);

$builder->create_build_script();
