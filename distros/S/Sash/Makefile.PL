use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sash',
    VERSION_FROM      => 'src/sash',
    PREREQ_PM         => {
        'Term::ShellUI' => 0.85,
        'Data::Table' => 1.50,
        'Text::ASCIITable' => 0.18,
        'Term::ReadKey' => 2.30,
        'Time::HiRes' => 1.86,
    },
    EXE_FILES => [ 'src/sash' ],
    ABSTRACT => 'A tool to communicate with database and API driven data sources',
    AUTHOR => 'Wes Bailey <wes@verticalresponse.com>',
);
