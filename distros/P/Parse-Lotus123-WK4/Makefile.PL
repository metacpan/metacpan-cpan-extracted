use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => "Parse::Lotus123::WK4",
    VERSION_FROM => 'lib/Parse/Lotus123/WK4.pm',
    'dist'       => {
        COMPRESS     => 'gzip -9f',
        SUFFIX       => 'gz',
        DIST_DEFAULT => 'all tardist',
        TAR => 'COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar'
    },
    MAN3PODS  => {},
    EXE_FILES => [ map { "bin/$_" } qw(wk42csv) ],
    LICENSE   => 'perl'
);
