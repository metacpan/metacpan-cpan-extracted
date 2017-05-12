use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Object::Lexical',
    'VERSION_FROM'	=> 'Lexical.pm', # finds $VERSION
    'PREREQ_PM'		=> { PadWalker => 0.08 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Lexical.pm', # retrieve abstract from module
       AUTHOR     => 'Scott Walters <scott@slowass.net>') : ()),
);
