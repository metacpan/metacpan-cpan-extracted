use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::FillInForm',
    'VERSION_FROM' => 'lib/Template/Plugin/FillInForm.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'Template' => 2.07,
	'HTML::FillInForm' => 0,
    },
);
