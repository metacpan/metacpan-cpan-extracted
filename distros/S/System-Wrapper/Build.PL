use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'System::Wrapper',
    license             => 'gpl3',
    dist_author         => 'Pedro Silva <pedros@berkeley.edu>',
    dist_version_from   => 'lib/System/Wrapper.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires       => {
        'version'    => 0,
        'overload'   => 0,
        'constant'   => 0,
        'Carp'       => 0,
        'File::Spec' => 0,
        'Storable'   => 0,
        'POSIX'      => 0,
        'Moose'      => 0,
    },
    script_files        => [ 'script/tpb.pl' ],
    add_to_cleanup      => [ 'System-Wrapper-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
    create_license      => 1,
);

$builder->create_build_script();
