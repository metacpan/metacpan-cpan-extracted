use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Parse::WebCounter',
    'VERSION_FROM'	=> 'WebCounter.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'GD'		=> '2.16',
		'Test::More'	=> 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'WebCounter.pm', # retrieve abstract from module
       AUTHOR     => 'Peter Wise <cpan@vagnerr.com>') : ()),
);
