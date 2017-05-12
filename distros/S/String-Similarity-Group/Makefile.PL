use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'String::Similarity::Group',
   VERSION_FROM => 'lib/String/Similarity/Group.pm',
   

   # gen /usr/bin/pmused by Fri Jul 17 11:54:21 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Getopt::Std::Strict'               => '1.01',
      'LEOCHARRE::Debug'                  => '1.01',
      'LEOCHARRE::Dir'                    => '1.07',
      'Smart::Comments'                   => '1',
      'String::Similarity'                => '1.03',
      'Test::Simple'                      => '0',
      'Time::Format'                      => '1.09',
      'Time::HiRes'                       => '1.86',
      'YAML'                              => '0.66',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/gbs)],
);


