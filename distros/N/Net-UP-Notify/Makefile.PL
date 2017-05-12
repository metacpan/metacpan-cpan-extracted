use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::UP::Notify',
    'VERSION_FROM'	=> 'Notify.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Notify.pm', # retrieve abstract from module
       AUTHOR     => 'Paul Timmins <paul@timmins.net>') : ()),
);
