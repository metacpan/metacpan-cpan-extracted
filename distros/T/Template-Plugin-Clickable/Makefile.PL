use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::Clickable',
    'VERSION_FROM' => 'lib/Template/Plugin/Clickable.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Template'   => 2.07,
	'URI::Find'  => 0.13,
	'UNIVERSAL::require' => 0,
    },
);
