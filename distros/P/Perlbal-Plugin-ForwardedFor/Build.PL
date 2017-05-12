use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perlbal::Plugin::ForwardedFor',
    license             => 'perl',
    dist_author         => q{Sawyer X <xsawyerx@cpan.org>},
    dist_version_from   => 'lib/Perlbal/Plugin/ForwardedFor.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'    => 5.006,
        'Perlbal' => 0,
    },
    add_to_cleanup      => [ 'Perlbal-Plugin-ForwardedFor-*' ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
    create_readme      => 1,
);

$builder->create_build_script();
