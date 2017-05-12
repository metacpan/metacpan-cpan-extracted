use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::StickyQuery',
    'VERSION_FROM' => 'lib/Template/Plugin/StickyQuery.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Template' => 2.07,
	'HTML::StickyQuery' => 0,
    },
);
