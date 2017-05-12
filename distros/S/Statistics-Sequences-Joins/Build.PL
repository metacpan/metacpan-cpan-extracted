use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup => ['Statistics-Sequences-Joins-0.20-*'],
    build_requires => {
        'Test::More' => '0.98',
    },
    configure_requires => {
        'Module::Build' => 0.421,
    },
    create_makefile_pl => 'traditional',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_abstract      => 'lib/Statistics/Sequences/Joins.pm',
    dist_version_from  => 'lib/Statistics/Sequences/Joins.pm',
    license            => 'perl',
    module_name        => 'Statistics::Sequences::Joins',
    requires           => {
        'Statistics::Sequences'         => '0.14',
        'List::AllUtils'                => '0.09',
        'Statistics::Zed'               => '0.10',
    },
);

$builder->create_build_script();

1;
