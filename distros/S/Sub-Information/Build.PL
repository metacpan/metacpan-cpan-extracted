use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Sub::Information',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Sub/Information.pm',
    requires          => {
        'B'                    => 0,
        'Test::More'           => 0,
        'Data::Dump::Streamer' => 1.14,
        'Devel::Peek'          => 0,
        'PadWalker'            => 0,
        'Sub::Identify'        => 0,
        'Scalar::Util'         => 0,
    },
    add_to_cleanup     => ['Sub-Information-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
