use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojolicious::Command::generate::bootstrap',
    VERSION_FROM      => 'lib/Mojolicious/Command/generate/bootstrap.pm', # finds $VERSION
    PREREQ_PM         => {
	 	Mojolicious => 3.11
	 }, # e.g., Module::Name => 1.1
    ($] >= 5.010 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mojolicious/Command/generate/bootstrap.pm', # retrieve abstract from module
       AUTHOR         => 'Sven Eppler (cpan@sveneppler.de)') : ()),
);
