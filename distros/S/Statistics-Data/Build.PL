use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::Data',
    license           => 'perl',
    dist_author       => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from => 'lib/Statistics/Data.pm',
    dist_abstract =>
      'Load, access, update one or more data lists for statistical analysis',
    configure_requires => {
        'Module::Build' => '0.4214',
    },
    build_requires => {
        'Test::More'     => '0.98',
        'Array::Compare' => '2.11',
    },
    requires => {
        'Clone'             => '0.38',
        'List::AllUtils'    => '0.09',
        'Number::Misc'      => '1.2',
        'Scalar::Util'      => '1.41',
        'String::Util'      => '1.24',
        'Text::SimpleTable' => '2.03',
    },
    add_to_cleanup     => ['Statistics-Data-0.11-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
1;
