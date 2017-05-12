use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Statistics::Sequences::Runs',
    license           => 'perl',
    dist_author       => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from => 'lib/Statistics/Sequences/Runs.pm',
    dist_abstract =>
      'descriptives, deviation and combinatorial tests of Wald-Wolfowitz runs',
    build_requires => {
        'Array::Compare' => '2.11',
        'Test::More'     => '0.98',
    },
    configure_requires => {
        'Module::Build' => '0.4210',
    },
    requires => {
        'perl'                  => 5.006,
        'List::AllUtils'        => '0.09',
        'Number::Misc'          => '1.2',
        'Statistics::Zed'       => '0.10',
        'Statistics::Sequences' => '0.15',
        'String::Numeric'       => '0.9',
    },
    add_to_cleanup     => ['Statistics-Sequences-Runs--*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;

