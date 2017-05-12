use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SVK::Log::Filter::Date',
    license             => 'mit',
    dist_version_from   => 'lib/SVK/Log/Filter/Date.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    requires => {
        'SVK'                => '1.99',
        'Date::PeriodParser' => '0.04',
        'Time::Local'        => 0,      # in core since perl 5
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'SVK-Log-Filter-Date-*' ],
);

$builder->create_build_script();
