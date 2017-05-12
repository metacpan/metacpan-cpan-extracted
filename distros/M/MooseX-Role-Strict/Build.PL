use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'MooseX::Role::Strict',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/MooseX/Role/Strict.pm',
    build_requires    => { 'Test::More' => 0.96, },
    requires          => {
        'Moose' => 0.89,    # for --metaclass, -excludes
    },
    meta_merge => {
        resources =>
          { repository => 'http://github.com/Ovid/MooseX--Role--Strict' }
    },
    add_to_cleanup     => ['MooseX-Role-Strict-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
