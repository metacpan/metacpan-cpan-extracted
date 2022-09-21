###############################################################################
##                                                                           ##
##  Copyright (c) 2022 - by Carlos Celso.                                    ##
##  All rights reserved.                                                     ##
##                                                                           ##
##  This package is free software; can, at your discretion, also be used,    ##
##  modified and redistributed under the terms of the "GPLv3 - GNU Library   ##
##  General Public License".                                                 ##
##                                                                           ##
###############################################################################

	use 5.006001;

	use ExtUtils::MakeMaker;

	WriteMakefile(
		NAME		=> 'SQL::SimpleOps',
		VERSION_FROM	=> 'lib/SQL/SimpleOps.pm',
		PREREQ_PM	=>
		{
			Date::Calc => 0,
			DBI => 0,
			File::Path => 0,
			File::Spec => 0,
			IO::File => 0,
			JSON => 0,
			Sys::Syslog => 0,
		},
		ABSTRACT_FROM	=> 'lib/SQL/SimpleOps.pod',
		AUTHOR		=> 'Carlos Celso <ccelso@cpan.org>',
    		LICENSE		=> 'GPL_3',
		dist		=> { COMPRESS => "gzip -9", SUFFIX => "gz"},
	);

##ENDED
