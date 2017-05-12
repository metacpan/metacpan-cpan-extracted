use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'      => 'Plucene::Plugin::FileDocument',
	'VERSION_FROM' => 'lib/Plucene/Plugin/FileDocument.pm',
	'PREREQ_PM' => {
		'Plucene' => '1.01',
	},
);
