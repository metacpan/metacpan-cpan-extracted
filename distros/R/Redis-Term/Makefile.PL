use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Redis::Term',
    VERSION_FROM      => 'lib/Redis/Term.pm',
    EXE_FILES         => [ "redist" ],
    PREREQ_PM         => {
                             'Term::ReadLine' => 1.14,
                             'Term::ReadLine::Perl' => 1.0303,
                             'Term::ReadKey' => 2.30,
                             'Text::TabularDisplay' => 1.35,
                             'Redis' => 1.972,
                             'Getopt::Std' => 0,
                             'List::MoreUtils' => 0,
                             'Storable' => 0,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Redis/Term.pm',
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
