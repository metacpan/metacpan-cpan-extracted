use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Statistics::ANOVA::Page',
    license            => 'Perl_5',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Statistics/ANOVA/Page.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4210',
    },
    build_requires => {
        'Test::More' => '0.98',
    },
    requires => {
        'List::AllUtils'         => '0.09',
        'Math::Cephes'           => '0.5304',
        'Statistics::Data'       => '0.11',
        'Statistics::Data::Rank' => '0.01',
        'Statistics::Zed'        => '0.10',
    },
    add_to_cleanup     => ['Statistics-ANOVA-Page-0.02-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
1;
