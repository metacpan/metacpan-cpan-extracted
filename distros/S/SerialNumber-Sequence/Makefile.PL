use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'SerialNumber::Sequence',
    'VERSION_FROM' => 'Sequence.pm', # finds $VERSION
    'DISTNAME'     => 'SerialNumber-Sequence',
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);
