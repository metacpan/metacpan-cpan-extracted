use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::XUL',
    'VERSION_FROM'	=> 'lib/POE/Component/XUL.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		POE => undef,
		XUL::Node => 0.05,
		Carp => undef,
		Digest::MD5 => undef,
		Aspect => undef,
		Time::HiRes => undef,
	},
);
