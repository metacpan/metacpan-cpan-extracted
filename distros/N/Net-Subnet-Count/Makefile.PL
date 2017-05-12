use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Subnet::Count',
    'VERSION_FROM' => 'Count.pm', # finds $VERSION
	      'PREREQ_PM' => {
			      'IP::Address' => '1.00',
			      },
);
