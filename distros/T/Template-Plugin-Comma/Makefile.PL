use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::Comma',
    'VERSION_FROM' => 'lib/Template/Plugin/Comma.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Template' => 2.07,
    },
);
