use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Security::CVSS',
    'VERSION_FROM'	=> 'CVSS.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Module::Check_Args', 'Carp' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Periscan <cpan@periscan.com>') : ()),
);
