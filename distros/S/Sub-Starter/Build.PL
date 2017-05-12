use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sub::Starter',
    license             => 'gpl',
    dist_author         => 'Shawn H Corey <SHCOREY@cpan.org>',
    dist_version_from   => 'lib/Sub/Starter.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Sub-Starter-*' ],
    create_makefile_pl => 'traditional',
    script_files => {
      'script/substarter' => 1,
    },
);

$builder->create_build_script();
