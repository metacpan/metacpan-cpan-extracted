use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Charset::UTF8::I18N',
    'VERSION_FROM' => 'lib/Sledge/Charset/UTF8/I18N.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
