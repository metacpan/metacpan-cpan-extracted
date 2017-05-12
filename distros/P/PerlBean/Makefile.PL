# $Revision: 1.0 $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'PerlBean',
	VERSION_FROM	=> 'lib/PerlBean.pm', # finds $VERSION
	PREREQ_PM	=> {
		Error => 0,
	},
	($] >= 5.005 ? ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM => 'lib/PerlBean.pm', # retrieve abstract from module
	AUTHOR => 'Vincenzo Zocca <Vincenzo@Zocca.com>') : ()),
	clean => {
		FILES => 'auto tmp diff-all pod-all sdiff-all',
	},
);
