use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::Jcode',
    'VERSION_FROM' => 'lib/Template/Plugin/Jcode.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More       => 0.32,
	Jcode            => 0.82,
	Template         => 2.08,
    },
);
