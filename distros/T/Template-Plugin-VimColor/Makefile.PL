use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Plugin::VimColor',
    VERSION_FROM      => 'lib/Template/Plugin/VimColor.pm',
    PREREQ_PM         => {
	Text::VimColor => '0.04'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/VimColor.pm', # retrieve abstract from module
       AUTHOR         => 'Naoya Ito <naoya@bloghackers.net>') : ()),
);
