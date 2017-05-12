use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::TagRescue',
    'VERSION_FROM' => 'lib/Template/Plugin/TagRescue.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Template' => 2.07,
	'HTML::Parser' => 3.08,
    },
);
