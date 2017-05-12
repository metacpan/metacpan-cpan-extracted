use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'String::Buffer',
    'VERSION_FROM' => 'Buffer.pm', # finds $VERSION
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
);
