use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Provider::Encoding',
    'VERSION_FROM' => 'lib/Template/Provider/Encoding.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Template   => 2.10,
        Encode     => 1.00,
    },
);
