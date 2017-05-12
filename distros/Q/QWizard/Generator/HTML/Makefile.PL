use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%opts = (
	      'NAME'		=> 'QWizard::Generator::HTML::Vertical',
	      'VERSION_FROM'	=> 'Vertical.pm', # finds $VERSION
	);

WriteMakefile(%opts);
