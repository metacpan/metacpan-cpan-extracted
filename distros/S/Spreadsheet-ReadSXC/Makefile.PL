use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spreadsheet::ReadSXC',
    VERSION_FROM      => 'ReadSXC.pm', # finds $VERSION
    PREREQ_PM         => {
				'XML::Parser'	=> 0,
				'Archive::Zip'	=> 0,
				'Test::More'	=> 0,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'ReadSXC.pm', # retrieve abstract from module
       AUTHOR         => 'Christoph Terhechte <terhechte@cpan.org>') : ()),
);
