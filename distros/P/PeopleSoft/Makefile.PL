use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PeopleSoft',
    'VERSION_FROM'	=> 'lib/PeopleSoft.pm', # finds $VERSION
     PREREQ_PM          => {
			    'DBI'            => 0,
			    'Data::Dumper'   => 0,
			    'Getopt::Std'    => 0,
			    'Time::Local'    => 0,
			    'Graph'          => 0,
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/PeopleSoft.pm', # retrieve abstract from module
       AUTHOR     => 'William Goedicke <goedicke@goedsole.com>') : ()),
);
