use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tanker',
    'VERSION_FROM'	=> 'Tanker.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             Data::Dumper => 0,
			     Net::IRC     => 0, 
			     POE          => 0.18,	
			     POE::Component::IRC => 1.9,
			   },
#    'EXE_FILES'         => [ 'tanker' ],

     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'Tanker.pm', # retrieve abstract from module
       AUTHOR           => 'Simon Wistow <simon@thegestalt.org>') : ()
     ),

);
