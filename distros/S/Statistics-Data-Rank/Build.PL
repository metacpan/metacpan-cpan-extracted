use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Statistics::Data::Rank',
    license            => 'Perl_5',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Statistics/Data/Rank.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.421',
    },
    build_requires => {
        'Array::Compare' => '2.11',
        'Test::More'     => '0.98',
    },
    requires => {
        'List::AllUtils'   => '0.09',
        'Statistics::Data' => '0.09',
        'Statistics::Lite' => '3.2',
        'String::Util'     => '1.24',
    },
    add_to_cleanup     => ['Statistics-Data-Rank-0.02-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
