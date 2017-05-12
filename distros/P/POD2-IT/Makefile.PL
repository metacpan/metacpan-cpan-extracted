use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POD2::IT',
    'VERSION_FROM'	=> 'IT.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'IT.pm', # retrieve abstract from module
       AUTHOR     => 'Enrico Sorcinelli and Italian Perl Mongers <bepi@perl.it>') : ()),
);
