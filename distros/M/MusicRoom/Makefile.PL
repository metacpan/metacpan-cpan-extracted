use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MusicRoom',
    AUTHOR              => q{Steve Hawtin <steve@tsort.demon.co.uk>},
    VERSION_FROM        => 'lib/MusicRoom.pm',
    ABSTRACT_FROM       => 'lib/MusicRoom.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Cwd' => 0,
        'IO::File' => 0,
        'DBI' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MusicRoom-*' },
);
