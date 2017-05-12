use strict;
use warnings;
use 5.010000;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Net::CIDR::ORTC',
	VERSION_FROM => 'lib/Net/CIDR/ORTC.pm',
	($] >= 5.005 ?
		(ABSTRACT_FROM => 'lib/Net/CIDR/ORTC.pm',
		AUTHOR         => 'Anton Yuzhaninov <ayuzhaninov@openstat.ru>') : ()),
	PREREQ_PM     => { 'Carp' => 0, },
	LICENSE => 'perl',
	META_MERGE => { resources => {
						bugtracker => 'https://bitbucket.org/citrin/p5-net-cidr-ortc/issues',
						repository => 'https://bitbucket.org/citrin/p5-net-cidr-ortc/src',
						license => 'http://dev.perl.org/licenses/',
				} },
);
