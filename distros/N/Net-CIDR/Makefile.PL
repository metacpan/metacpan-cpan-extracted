use ExtUtils::MakeMaker;
# $Revision: 1.2 $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'		=> 'Sam Varshavchik <sam@email-scan.com>',
    'ABSTRACT_FROM'	=> 'CIDR.pm',
    'NAME'		=> 'Net::CIDR',
    'VERSION_FROM'	=> 'CIDR.pm', # finds $VERSION
    'PREREQ_PM'	=> { 'Carp' => 0 }, # e.g., Module::Name => 1.1
    'LICENSE' => 'perl',
    'PL_FILES' => { 'Net-CIDR.spec.PL' => 'Net-CIDR.spec' }
);
