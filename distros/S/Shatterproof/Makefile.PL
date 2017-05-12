use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Shatterproof',
    VERSION_FROM      => 'lib/Shatterproof.pm', # finds $VERSION
    PREREQ_PM         => {
				'Statistics::Distributions' => 1.02,
				'File::Basename' => 2.00,
				'List::Util' => 1.00,
				'POSIX' => 1.00,
				'JSON::XS' => 2.30,
				'Test::More' => 0,
				'Test::Exception' => 0,
				'Test::Deep' => 0
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Shaylan Govind <shaylan.govind@oicr.on.ca>') : ()),
);
