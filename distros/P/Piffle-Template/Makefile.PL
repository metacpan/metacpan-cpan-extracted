use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	  => 'Piffle::Template',
    VERSION_FROM  => 'lib/Piffle/Template.pm',
    PREREQ_PM	  => {}, # e.g., Module::Name => 1.1
    # ABSTRACT_FROM => 'XXX', # retrieve abstract from module
    AUTHOR	  => 'Andrew Chadwick <andrewc-templatedotpm@piffle.org>',
);
