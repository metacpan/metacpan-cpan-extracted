use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'News::Pan',
   VERSION_FROM => 'lib/News/Pan/Server.pm',
   PREREQ_PM => {
      'LEOCHARRE::DEBUG' => 0,
      'LEOCHARRE::CLI' => 0,
   },

   EXE_FILES => ['bin/panfind'],

);
