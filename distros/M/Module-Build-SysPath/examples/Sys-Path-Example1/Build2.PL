use strict;
use warnings;
use Module::Build::SysPath;

my $builder = Module::Build::SysPath->new(
    module_name         => 'Sys::Path::Example1',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Sys/Path/Example1.pm',
    build_requires => {
        'Test::More' => 0,
        'Cwd'        => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-Example1-*' ],
);

$builder->create_build_script();
