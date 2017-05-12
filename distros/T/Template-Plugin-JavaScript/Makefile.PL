use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::JavaScript',
    'VERSION_FROM' => 'lib/Template/Plugin/JavaScript.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Template => 0,
    },
);
