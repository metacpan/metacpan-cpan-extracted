use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Parse::Tokens',
    'VERSION_FROM' => 'Tokens.pm', # finds $VERSION
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
);
