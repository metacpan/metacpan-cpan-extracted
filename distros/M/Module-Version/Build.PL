use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Module::Version',
    license            => 'perl',
    dist_author        => q{Sawyer X <xsawyerx@cpan.org>},
    dist_version_from  => 'lib/Module/Version.pm',
    build_requires     => {
        'Test::More' => 0,
    },
    requires           => {
        'Carp'                => 0,
        'autodie'             => 0,
        'Exporter'            => 0,
        'Getopt::Long'        => 0,
        'ExtUtils::MakeMaker' => 6.56,
    },
    add_to_cleanup     => [ 'Module-Version-*' ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
    create_readme      => 1,
);

$builder->create_build_script();
