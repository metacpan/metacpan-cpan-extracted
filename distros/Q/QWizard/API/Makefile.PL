use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
	      'NAME'		=> 'QWizard::API',
	      'VERSION_FROM'	=> 'API.pm', # finds $VERSION
	);

WriteMakefile(%opts);
