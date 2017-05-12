use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Template::TT::I18N',
    'VERSION_FROM' => 'lib/Sledge/Template/TT/I18N.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
