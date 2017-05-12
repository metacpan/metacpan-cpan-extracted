use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Template::Plugin::MobileAgent',
    'VERSION_FROM' => 'lib/Template/Plugin/MobileAgent.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Template =>   2.08,
	HTTP::MobileAgent => 0.04,
    },
);
