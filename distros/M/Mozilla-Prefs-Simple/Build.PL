use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mozilla::Prefs::Simple',
    requires => {
       'perl'                       => '5.006',
       'Carp'                       => 0,
       'File::Copy'                 => 0,
       'IO::File'                   => 0,
       'Regexp::Common'             => 0,
       'Tie::Hash::Sorted'          => 0.10,
    },
    build_requires => {
        'Test::More' => 0,
    },
    license             => 'perl',
    dist_version_from   => 'lib/Mozilla/Prefs/Simple.pm',
    add_to_cleanup      => [ 'Mozilla-Prefs-Simple-*' ],
    create_readme      => ($Module::Build::VERSION >= 0.2702),
    create_makefile_pl => 'traditional',
    dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
    sign               => 0,
);

$builder->create_build_script();
