use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MSN',
    'VERSION_FROM'	=> 'MSN.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Digest::MD5 => 2.30
    }, # e.g., Module::Name => 1.1
);
