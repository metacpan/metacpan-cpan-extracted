use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Plugin::Markdown',
    VERSION_FROM      => 'lib/Template/Plugin/Markdown.pm',
    PREREQ_PM         => {
	Text::Markdown => '1.0.1'
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Template/Plugin/Markdown.pm',
       AUTHOR         => 'Naoya Ito <naoya@bloghackers.net>') : ()),
);
