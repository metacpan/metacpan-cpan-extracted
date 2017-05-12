use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Plugin::Hatena',
    VERSION_FROM      => 'lib/Template/Plugin/Hatena.pm', # finds $VERSION
    PREREQ_PM         => {
	Test::More   => 0.32,
	Template     => 2.08,
	Text::Hatena => 0.01,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/Hatena.pm', # retrieve abstract from module
       AUTHOR         => 'Naoya Ito <naoya@bloghackers.net>') : ()),
);
