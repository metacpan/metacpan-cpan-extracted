use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Nessus::ScanLite',
    VERSION_FROM      => 'lib/Net/Nessus/ScanLite.pm', # finds $VERSION
    PREREQ_PM         => {
	        IO::Socket::SSL         => 0.90,
                Net::Nessus::Client     => 0.0,
                Net::Nessus::Message    => 0.0,
                Config::IniFiles        => 0.0,
		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Nessus/ScanLite.pm', # retrieve abstract from module
       AUTHOR         => 'John Ballem <jpb@brown.edu>') : ()),
);
