#
# Distribution:	SQL::Generator
#
# Author:	Murat Uenalan (muenalan@cpan.org)
#
# Copyright:	Copyright (c) 1997 Murat Uenalan. All rights reserved.
#
# Note:		This program is free software; you can redistribute it and/or modify it
#
#		under the same terms as Perl itself.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(

	'NAME'		=> 'SQL::Generator',

	'AUTHOR'	=> 'Murat Uenalan (muenalan@cpan.org)',

	'ABSTRACT'	=> 'Generate SQL-statements via oo-perl',

	'VERSION_FROM'	=> 'Generator.pm', # finds $VERSION

	'PREREQ_PM'	=>
	{
		'Class::Maker' => 0,

	}, # e.g., Module::Name => 1.1
);
