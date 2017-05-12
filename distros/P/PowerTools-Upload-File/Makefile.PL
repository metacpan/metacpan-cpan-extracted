use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PowerTools::Upload::File',
    VERSION_FROM      => 'lib/PowerTools/Upload/File.pm', # finds $VERSION
    PREREQ_PM         => {
	Apache::ASP => '2.59',
	File::Scan::ClamAV => '1.8'
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PowerTools/Upload/File.pm', # retrieve abstract from module
       AUTHOR         => 'Piotr Ginalski <office@gbshouse.com>') : ()),
);
