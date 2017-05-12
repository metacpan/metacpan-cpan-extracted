use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		    => 'String::Canonical',
    VERSION_FROM	=> 'Canonical.pm',
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'Canonical.pm',
    PREREQ_PM       => {
        Test::Simple => 0,
        Lingua::EN::Numericalize => 0,
        Text::Roman => 0,
        }
	);
