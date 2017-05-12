#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'			=> 'POE::TIKC',
    'VERSION_FROM'	=> 'lib/POE/TIKC.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'POE'		=>	'0.20',
		'POE::Filter::Reference' => undef,
    },
);
