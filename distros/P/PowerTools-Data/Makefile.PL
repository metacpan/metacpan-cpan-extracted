use 5.000005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PowerTools::Data',
    VERSION_FROM      => 'lib/PowerTools/Data.pm', # finds $VERSION
    PREREQ_PM         => {
	DBI => '1.52',
	DBD::mysql => '4.001',
	Time::Piece => '1.11',
	Time::Piece::MySQL => '0.03',
	Time::HiRes => '1.87',
	Config::IniHash => '2.8'
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PowerTools/Data.pm', # retrieve abstract from module
       AUTHOR         => 'Piotr Ginalski <office@gbshouse.com>') : ()),
);
