use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Module::Filename',
    VERSION_FROM => 'lib/Module/Filename.pm',
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Returns the filename for a given module',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Path::Class'  => 0,
                     'strict'       => 0,
                    },
);
