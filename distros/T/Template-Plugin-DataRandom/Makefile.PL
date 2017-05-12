use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::DataRandom',
    VERSION_FROM      => 'lib/Template/Plugin/DataRandom.pm', # finds $VERSION
    PREREQ_PM         => {'Data::Random' => '0.05',
			  'Template::Plugin' => '2.7',
			  'Template'         => '2.20',
			  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/DataRandom.pm', # retrieve abstract from module
       AUTHOR         => 'Emmanuel Quevillon <tuco@pasteur.fr>') : ()),
);
