use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Plack::Middleware::CSS::Compressor',
	'VERSION_FROM'	=> 'lib/Plack/Middleware/CSS/Compressor.pm',
	'PREREQ_PM'	=> {
		'CSS::Compressor'	=> 0,
		'Plack'			=> 0,
	},
	'ABSTRACT_FROM'	=> 'lib/Plack/Middleware/CSS/Compressor.pm',
	'AUTHOR'	=> 'Simon Bertrang <janus@cpan.org>',
);

