use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
	      'NAME'		=> 'QWizard::Generator::Best',
	      'VERSION_FROM'	=> 'Best.pm', # finds $VERSION
	);

WriteMakefile(%opts);
