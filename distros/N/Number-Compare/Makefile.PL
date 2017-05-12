use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Number::Compare',
    VERSION_FROM => 'lib/Number/Compare.pm',
    PREREQ_PM => {
       'Test::More' => 0,
   },
);
