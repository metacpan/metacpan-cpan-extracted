use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PDF::Report::Table',
    VERSION_FROM      => 'lib/PDF/Report/Table.pm', # finds $VERSION
    PREREQ_PM         => {
    				PDF::Report => 1.00,
				PDF::Table => 0.01,
    			 }, # e.g., Module::Name => 1.1
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PDF/Report/Table.pm', # retrieve abstract from module
       AUTHOR         => 'Aaron Mitti <mitti@cpan.org>') : ()),
);
