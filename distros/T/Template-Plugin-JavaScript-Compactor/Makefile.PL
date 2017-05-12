use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Plugin::JavaScript::Compactor',
    VERSION_FROM      => 'lib/Template/Plugin/JavaScript/Compactor.pm', # finds $VERSION
    PREREQ_PM         => {
	Test::More => 0.32,
	Template => 2.08,
	Data::JavaScript::Compactor => 0.02,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/JavaScript/Compactor.pm', # retrieve abstract from module
       AUTHOR         => 'Naoya Ito <naoya@bloghackers.net>') : ()),
);
