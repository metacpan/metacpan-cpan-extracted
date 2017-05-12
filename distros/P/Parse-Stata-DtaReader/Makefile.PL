use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => "Parse::Stata::DtaReader",
    VERSION_FROM => 'lib/Parse/Stata/DtaReader.pm',
    'dist'       => {
        COMPRESS     => 'gzip -9f',
        SUFFIX       => 'gz',
        DIST_DEFAULT => 'all tardist',
        TAR => 'COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar'
    },
    MAN3PODS  => {},
    EXE_FILES => [ map { "bin/$_" } qw(dta2csv dta2sql) ],
    LICENSE   => 'perl'
);
