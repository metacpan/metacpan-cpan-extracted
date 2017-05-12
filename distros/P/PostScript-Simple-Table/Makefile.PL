use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PostScript::Simple::Table',
    VERSION_FROM      => 'lib/PostScript/Simple/Table.pm', # finds $VERSION
    PREREQ_PM         => { 
                           PostScript::Simple => 0.05, 
                           PostScript::Metrics => 0.06,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PostScript/Simple/Table.pm', # retrieve abstract from module
       AUTHOR         => 'Aaron Mitti <mitti@cpan.org>') : ()),
);
