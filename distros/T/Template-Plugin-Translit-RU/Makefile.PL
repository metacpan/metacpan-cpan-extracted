use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::Translit::RU',
    VERSION_FROM      => 'lib/Template/Plugin/Translit/RU.pm', # finds $VERSION
    PREREQ_PM         => {
	'Template'	=> '0'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/Translit/RU.pm', # retrieve abstract from module
       AUTHOR         => 'Igor Lobanov <igor.lobanov@gmail.com>') : ()),
);
