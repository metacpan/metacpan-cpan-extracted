use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Nginx::ReadBody',
    VERSION_FROM      => 'lib/Nginx/ReadBody.pm', # finds $VERSION
    PREREQ_PM         => {'nginx' => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Nginx/ReadBody.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Podolsky <tpaba@cpan.org>') : ()),
);
