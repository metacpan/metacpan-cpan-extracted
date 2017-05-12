use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PowerTools::Upload::Blob',
    VERSION_FROM      => 'lib/PowerTools/Upload/Blob.pm', # finds $VERSION
    PREREQ_PM         => {
	DBI => '1.52',
	DBD::mysql => '4.001',
	Apache::ASP => '2.59',
	File::Scan::ClamAV => '1.8'
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Piotr Ginalski <office@gbshouse.com>') : ()),
);
