use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Filter::Ls',
    'VERSION_FROM'	=> 'Ls.pm', # finds $VERSION
    'PREREQ_PM'		=> { POE::Filter::Line => 0,
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Ls.pm', # retrieve abstract from module
       AUTHOR     => 'Michael Ching <michaelc@wush.net>') : ()),
);
