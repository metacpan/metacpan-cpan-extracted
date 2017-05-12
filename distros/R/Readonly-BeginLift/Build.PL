use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Readonly::BeginLift',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Readonly/BeginLift.pm',
    requires          => {
        'Devel::BeginLift' => 0.001002,
        'parent'           => 0.221,
        'Readonly'         => 1.03,
    },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Readonly-BeginLift-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
