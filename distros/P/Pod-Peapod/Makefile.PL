use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Pod::Peapod',
    'VERSION_FROM'	=> 'Peapod.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
	'Tk' => '800.015',
	'Pod::Simple' => '0.96',
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Peapod.pm', # retrieve abstract from module
       AUTHOR     => 'Greg London <DELETEALLCAPSemail@greglondon.com>') : ()),
);

