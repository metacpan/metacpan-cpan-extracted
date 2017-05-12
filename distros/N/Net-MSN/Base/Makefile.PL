use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MSN::Base',
    'VERSION_FROM'	=> 'Base.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Hash::Merge => 0.07,
	IO::Socket => 1.27,
	IO::Select => 1.15
    }, # e.g., Module::Name => 1.1
);
