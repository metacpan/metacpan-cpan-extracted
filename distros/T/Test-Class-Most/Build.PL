use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Class::Most',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Test/Class/Most.pm',
    requires          => {
        'Test::Most'  => 0.31,
        'Test::Class' => 0.38,
    },
    meta_merge        => {
        resources =>
          { repository => 'http://github.com/Ovid/Test-Class-Most/', },
    },
    add_to_cleanup     => ['Test-Class-Most-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
