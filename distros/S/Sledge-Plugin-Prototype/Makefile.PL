use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Plugin::Prototype',
    'VERSION_FROM' => 'lib/Sledge/Plugin/Prototype.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    HTML::Prototype => 0,
    },
);
