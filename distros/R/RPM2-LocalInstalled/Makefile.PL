use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> 'RPM2::LocalInstalled',
	VERSION_FROM		=> 'lib/RPM2/LocalInstalled.pm',
	PREREQ_PM			=> {
							RPM2 => 0,
							Sort::Versions => 0,
						},
    ($] >= 5.005 ?
      (ABSTRACT_FROM	=> 'lib/RPM2/LocalInstalled.pm',
       AUTHOR			=> 'Oliver Falk <oliver@linux-kernel.at>') : ()),
	dist				=> {
		COMPRESS => 'gzip --force --best'
	},
);
