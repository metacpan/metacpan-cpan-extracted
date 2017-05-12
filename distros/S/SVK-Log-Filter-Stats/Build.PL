use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SVK::Log::Filter::Stats',
    license             => 'mit',
    dist_version_from   => 'lib/SVK/Log/Filter/Stats.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    requires => {
        SVK           => '1.99',
        'List::Util'  => 0,
        'Time::Local' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SVK-Log-Filter-Stats-*' ],
);

$builder->create_build_script();
