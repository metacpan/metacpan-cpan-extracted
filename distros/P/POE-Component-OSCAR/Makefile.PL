use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::OSCAR',
    VERSION_FROM      => 'lib/POE/Component/OSCAR.pm', # finds $VERSION
	PREREQ_PM         => {
		'Net::OSCAR' => 0.62,
		'POE'        => 0.28,
		'Time::HiRes' => 0.01,
		'Filter::Template' => 1.02,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/OSCAR.pm', # retrieve abstract from module
       AUTHOR         => 'Dan McCormick <dan@codeop.com>') : ()),
);
