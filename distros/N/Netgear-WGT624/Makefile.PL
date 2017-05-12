use 5.008;
use ExtUtils::MakeMaker;

my @programs_to_install = ( 'bin/get-wgt624-status' );

WriteMakefile(
	      NAME              => 'Netgear::WGT624',
	      EXE_FILES         => \@programs_to_install,
	      INSTALLSCRIPT     => '/usr/local/bin',
	      VERSION_FROM      => 'lib/Netgear/WGT624.pm', # finds $VERSION
	      PREREQ_PM         => { LWP::UserAgent  => 1.73 },
	      
	      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/Netgear/WGT624.pm', # retrieve abstract from module
		AUTHOR         => 'Justin S. Leitgeb <justin@phq.org>') : ()),
);
