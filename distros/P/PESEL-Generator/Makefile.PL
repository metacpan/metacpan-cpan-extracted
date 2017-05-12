use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'PESEL::Generator',
    AUTHOR			=> 'Lukasz Strzelecki <lukasz@strzeleccy.eu>',
    VERSION_FROM	=> 'lib/PESEL/Generator.pm',
    ABSTRACT_FROM	=> 'lib/PESEL/Generator.pm',
    PL_FILES		=> {},
    PREREQ_PM		=> {
		'Exporter::Tiny'			=> 0.042,
		'Identifier::PL::PESEL'		=> 0.2,
    },
);
