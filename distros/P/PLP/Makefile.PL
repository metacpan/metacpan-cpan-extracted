use 5.006;
use strict;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME          => 'PLP',
	VERSION_FROM  => 'lib/PLP.pm',
	PREREQ_PM     => {},
	ABSTRACT_FROM => 'lib/PLP.pm',
	NO_META       => 1,
	(LICENSE      => 'mit') x ($ExtUtils::MakeMaker::VERSION > 6.30),
	AUTHOR        => 'Mischa POSLAWSKY <perl@shiar.org>',
);
