use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::EMI::Common',
    'VERSION_FROM'	=> 'Common.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Common.pm', # retrieve abstract from module
       AUTHOR     => 'Gustav Schaffter, <schaffter_cpan@hotmail.com>') : ()),
);

