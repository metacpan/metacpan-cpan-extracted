use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Sys::Filesystem::MountPoint',
   VERSION_FROM => 'lib/Sys/Filesystem/MountPoint.pm',
   

   # gen /usr/bin/pmused by Tue Jan 27 22:09:46 EST 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Getopt::Std::Strict'               => '1.01',
      'Sys::Filesystem'                   => '1.22',
      'Test::Simple'                      => '0',
   },


   EXE_FILES => [qw(bin/mounpointq)],
);


