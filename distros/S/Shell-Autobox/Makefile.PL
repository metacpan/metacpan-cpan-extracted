use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Shell::Autobox',
    VERSION_FROM      => 'lib/Shell/Autobox.pm', # finds $VERSION
    INSTALLDIRS       => 'perl',
    PREREQ_PM         => {
        autobox          => '1.03',
        'File::Temp'     => '0.16'
    }
);
