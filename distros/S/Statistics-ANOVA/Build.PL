use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::ANOVA',
    license           => 'Perl_5',
    dist_author       => 'Roderick Garton <rgarton@cpan.org>',
    dist_version_from => 'lib/Statistics/ANOVA.pm',
    build_requires    => {
        'Array::Compare' => '2.12.2',
        'Test::More'     => '0.98',
    },
    configure_requires => {
        'Module::Build' => '0.421',
    },
    requires => {
        'List::AllUtils'              => '0.09',
        'Math::Cephes'                => '0.5304',
        'Readonly'                    => '1.03',
        'Scalar::Util'                => '1.42',
        'Statistics::ANOVA::Friedman' => '0.01',
        'Statistics::ANOVA::JT'       => '0.01',
        'Statistics::ANOVA::KW'       => '0.01',
        'Statistics::ANOVA::Page'     => '0.01',
        'Statistics::Lite'            => '3.62',
        'Statistics::Data'            => '0.11',
        'Statistics::Data::Rank'      => '0.01',
        'Statistics::DependantTTest'  => '0.03',
        'Statistics::TTest'           => '1.1',
    },
    add_to_cleanup     => ['Statistics-ANOVA-0.14-*'],
    create_makefile_pl => 'traditional',
);
$builder->add_build_element('csv');
$builder->create_build_script();
1;
