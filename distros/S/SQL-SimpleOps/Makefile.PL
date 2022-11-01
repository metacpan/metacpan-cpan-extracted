#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) 2022 Carlos Celso
# 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
# 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
#
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#
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
