use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Statistics::ANOVA::JT',
    license            => 'Perl_5',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Statistics/ANOVA/JT.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.421',
    },
    build_requires => {
        'Test::More' => '0.98',
    },
    requires => {
        'Algorithm::Combinatorics' => '0.27',
        'List::AllUtils'           => '0.09',
        'Statistics::Data'         => '0.09',
        'Statistics::Data::Rank'   => '0.01',
        'Statistics::Lite'         => '3.2',
        'Statistics::Zed'          => '0.10',
    },
    add_to_cleanup     => ['Statistics-ANOVA-JT-0.01-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
