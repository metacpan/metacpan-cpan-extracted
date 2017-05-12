use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Request::Apache::I18N',
    'VERSION_FROM' => 'lib/Sledge/Request/Apache/I18N.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
