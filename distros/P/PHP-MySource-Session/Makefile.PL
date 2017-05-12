use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'PHP::MySource::Session',
    'VERSION_FROM' => 'lib/PHP/MySource/Session.pm', # finds $VERSION
    'PREREQ_PM' => {
	PHP::Session => 0.20,
	Test::More => 0.32,
	UNIVERSAL::require => 0.03,
    },
);
