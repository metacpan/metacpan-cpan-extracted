use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MusicBrainz::Collection',
    VERSION_FROM      => 'lib/MusicBrainz/Collection.pm', # finds $VERSION
    PREREQ_PM         => {
        'Audio::Scan'    => 0.58,
        'File::Next'     => 0,
        'LWP::UserAgent' => 0, 
    },
    EXE_FILES         => [ 'bin/mbcol' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MusicBrainz/Collection.pm', # retrieve abstract from module
       AUTHOR         => 'Andy Grundman <andy@hybridized.org>') : ()),
);
