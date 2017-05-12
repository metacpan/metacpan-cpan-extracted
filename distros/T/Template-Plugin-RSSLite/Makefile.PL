use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::RSSLite',
    'VERSION_FROM'	=> 'RSSLite.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Template' => 2,
		'XML::RSSLite' => 0.11
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RSSLite.pm', # retrieve abstract from module
       AUTHOR     => 'Kenneth Ekdahl (sensei@sensei.nu)') : ()),
);

