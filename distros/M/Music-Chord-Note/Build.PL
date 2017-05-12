use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Music::Chord::Note',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Music/Chord/Note.pm',
    requires => {
        'perl' => '5.6.2',
        'Test::More' => 0,
        'Carp'       => 0,
    },
    add_to_cleanup      => [ 'Music-Chord-Note-*' ],
);

$builder->create_build_script();
