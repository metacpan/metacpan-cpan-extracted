use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl6::Perl',
    VERSION_FROM      => 'lib/Perl6/Perl.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl6/Perl.pm', # retrieve abstract from module
       AUTHOR         => 'Dan Kogai <dankogai@dan.co.jp>') : ()),
);
