use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Plugin::IfModifiedSince',
    'VERSION_FROM' => 'lib/Sledge/Plugin/IfModifiedSince.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
