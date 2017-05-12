use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval { require 5.003_03 }
	or die <<EOL;
# This Module requires lvaluable subroutines, which are not avaiable
# in the version of Perl earlier than 5.6.0. Please upgrade!
EOL

WriteMakefile (
	'NAME'		=> 'Sort::Array',
	'VERSION_FROM'	=> 'Array.pm', # finds $VERSION
);
