use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sub::Lexical',
    'VERSION_FROM'	=> 'Lexical.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Regexp::Common	=> 0.01,
		Filter::Simple	=> 0.77,
	}, # e.g., Module::Name => 1.1
);
