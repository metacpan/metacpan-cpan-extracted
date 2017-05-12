use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Akismet',
    VERSION_FROM      => 'lib/Net/Akismet.pm', # finds $VERSION
    PREREQ_PM         => {
		'LWP'	=> '5.09',
	}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Akismet.pm', # retrieve abstract from module
       AUTHOR         => 'Nikolay Bachiyski <nbachiyski@developer.bg>') : ()),
);
