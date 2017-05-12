use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::HTML::Template',
    'VERSION_FROM' => 'lib/Template/Plugin/HTML/Template.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'HTML::Template' => 2.5,
	'Template' => 2.08,
    },
);
