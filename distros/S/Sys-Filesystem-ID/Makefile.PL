use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Sys::Filesystem::ID',
   VERSION_FROM => 'lib/Sys/Filesystem/ID.pm',

   # gen /usr/bin/pmused by Fri Apr 18 16:21:07 EDT 2008 
   PREREQ_PM => {
      'Cwd'                               => '3.12',
      'Exporter'                          => '5.58',
      'LEOCHARRE::CLI'                    => '1.14',
      'LEOCHARRE::DEBUG'                  => '1.11',
      'Sys::Filesystem'                   => '1.22',
   },

   EXE_FILES => [qw(bin/fsid bin/fsidgen)],
);


