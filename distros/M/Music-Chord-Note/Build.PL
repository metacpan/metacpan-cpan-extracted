use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Music-Chord-Note',
    module_name         => 'Music::Chord::Note',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Music/Chord/Note.pm',
    add_to_cleanup      => [ 'Music-Chord-Note-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Music-Chord-Note',
        bugtracker  => 'http://github.com/bayashi/Music-Chord-Note/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
