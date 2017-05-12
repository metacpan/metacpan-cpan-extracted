use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'String::Prettify',
   VERSION_FROM => 'lib/String/Prettify.pm',


   # gen /usr/bin/pmused by Tue Jun 10 14:15:09 EDT 2008 
   PREREQ_PM => {
      'Exporter'                          => 0,
      'Test::Simple'                      => 0,,
   },


   EXE_FILES => [],
);


