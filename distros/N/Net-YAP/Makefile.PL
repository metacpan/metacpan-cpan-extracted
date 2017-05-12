use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::YAP',
    'VERSION_FROM'	=> 'lib/Net/YAP.pm', # finds $VERSION
    'PREREQ_PM'         => { 'Net::OAuth::Simple' => 1.3 },
);
