use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SVK::Log::Filter::Mndrix',
    license             => 'mit',
    dist_version_from   => 'lib/SVK/Log/Filter/Mndrix.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    requires       => {
        'SVK'              => '1.99',
        'Perl6::Form'      => 0,
        'Text::Autoformat' => 0,
        'Term::ReadKey'    => 0,
        'Time::Local'      => 0,  # core
        'POSIX'            => 0,  # core
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SVK-Log-Filter-Mndrix-*' ],
);

$builder->create_build_script();
