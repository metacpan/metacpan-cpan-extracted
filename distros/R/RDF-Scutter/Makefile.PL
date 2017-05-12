use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RDF::Scutter',
    VERSION_FROM      => 'lib/RDF/Scutter.pm', # finds $VERSION
    PREREQ_PM         => {
	'RDF::Redland' => '1.0.2.1',
	'LWP::RobotUA' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RDF/Scutter.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Kjernsmo <kjetilk@cpan.org>') : ()),
);
