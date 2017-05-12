use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::Shuffle',
    'VERSION_FROM' => 'lib/Template/Plugin/Shuffle.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Template => 2.08,
	Algorithm::Numerical::Shuffle => 1.4,
    },
);
