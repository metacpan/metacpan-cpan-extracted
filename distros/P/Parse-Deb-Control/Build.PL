use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Parse::Deb::Control',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Parse/Deb/Control.pm',
    requires => {
        'Class::Accessor::Fast' => 0,
        'Storable'              => 0,
        'List::MoreUtils'       => 0,
        'IO::Any'               => 0.04,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'File::Spec'        => 0,
        'File::Slurp'       => 0,
    },
    script_files => [
        'script/deb-control-key-values',
        'script/deb-control-prefix-perl',
    ],
    add_to_cleanup     => [ 'Parse-Deb-Control-*' ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    sign               => 1,
);

$builder->create_build_script();
