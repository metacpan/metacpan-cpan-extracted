use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'PerlIO::via::ANSIColor',
    license             => 'perl',
    dist_author         => 'Masanori Hara <massa.hara at gmail.com>',
    dist_version_from   => 'lib/PerlIO/via/ANSIColor.pm',
    requires => {
        'Test::More'      => 0,
        'Term::ANSIColor' => 0,
    },
    add_to_cleanup      => [ 'PerlIO-via-ANSIColor-*' ],
);

$builder->create_build_script();
