use ExtUtils::MakeMaker;


WriteMakefile(
    ($] >= 5.005 ? (
    'AUTHOR'        => 'Kawai Takanori (kwitknr@cpan.org)',
    'ABSTRACT'      => 'Read and write OLE storage files.', ) : () ),
    'NAME'          => 'OLE::Storage_Lite',
    'VERSION_FROM'  => 'lib/OLE/Storage_Lite.pm',
    'NEEDS_LINKING' => 0,
    'PREREQ_PM'     => {},
    'dist'          => {COMPRESS => 'gzip --best', SUFFIX => 'gz'},


);
