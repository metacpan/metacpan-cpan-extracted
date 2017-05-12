use strict;
use warnings;
use Module::Build;
# $RedRiver$

my $builder = Module::Build->new(
    module_name         => 'Net::OpenAMD',
    license             => 'perl',
    dist_author         => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from   => 'lib/Net/OpenAMD.pm',
    build_requires => {
        'Test::More'  => 0,
        'Test::Deep'  => 0,
        'Mojolicious' => 0,
    },
    requires => {
        'version'        => 0,
        'LWP::UserAgent' => 0,
        'Net::OAuth'     => 0,
        'URI'            => 0,
        'JSON'           => 0,
    },
    add_to_cleanup      => [ 
        'Net-OpenAMD-*',
        'README',
        'Makefile.PL',
    ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);

$builder->create_build_script();
