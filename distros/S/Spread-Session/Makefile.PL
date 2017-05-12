use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Spread::Session',
    'VERSION_FROM'	=> 'Session.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Spread => "3.15.2-1.04",
#			    Log::Channel => "0.6",
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Session.pm', # retrieve abstract from module
       AUTHOR     => 'Jason W. May <jmay@pobox.com>') : ()),
);
