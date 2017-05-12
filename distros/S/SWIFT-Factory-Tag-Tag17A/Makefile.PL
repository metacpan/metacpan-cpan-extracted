use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SWIFT::Factory::Tag::Tag17A',
    'VERSION_FROM'	=> 'Tag17A.pm', # finds $VERSION
    'PREREQ_PM'		=> {SWIFT::Factory::Tag::Tag17=>0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Tag17A.pm', # retrieve abstract from module
       AUTHOR     => 'BIKER, <biker_cpan@hotmail.com>') : ()),
);

