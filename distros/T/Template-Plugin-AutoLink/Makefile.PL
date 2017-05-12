use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::AutoLink',
    'VERSION_FROM' => 'lib/Template/Plugin/AutoLink.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
