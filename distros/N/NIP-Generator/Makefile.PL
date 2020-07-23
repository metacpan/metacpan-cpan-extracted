use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'NIP::Generator',
    AUTHOR			=> 'Lukasz Strzelecki <lukasz@strzeleccy.eu>',
    VERSION_FROM	=> 'lib/NIP/Generator.pm',
    ABSTRACT_FROM	=> 'lib/NIP/Generator.pm',
    PL_FILES		=> {},
    PREREQ_PM		=> {
		'Exporter::Tiny'		=> 0.042,
		'Business::PL::NIP'		=> 0.03,
		'List::Util'			=> 0,
    },
);
