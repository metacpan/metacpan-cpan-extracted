use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::ROBODoc',
    license             => 'perl',
    dist_author         => q{Matt Grimm <mgrimm@cpan.org>},
    dist_version_from   => 'lib/Pod/ROBODoc.pm',
    add_to_cleanup      => [ 'Pod-ROBODoc-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    create_license      => 1,
    build_requires => {
        'Test::More'  => 0,
        'Test::Pod'   => 0,
        'File::Slurp' => 0,
    },
    requires => {
        'Carp'             => 0,
        'IO::File'         => 0,
        'IO::String'       => 0,
        'Getopt::Lucid'    => 0,
        'Params::Validate' => 0,
    },
);

$builder->create_build_script();
