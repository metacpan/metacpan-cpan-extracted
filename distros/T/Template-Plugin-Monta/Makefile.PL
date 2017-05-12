use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Plugin::Monta',
    VERSION_FROM      => 'lib/Template/Plugin/Monta.pm', # finds $VERSION
    PREREQ_PM         => {
		Acme::Monta	=> 0,
		Template	=> 2.14
	}, # e.g., Module::Name => 1.1
);
