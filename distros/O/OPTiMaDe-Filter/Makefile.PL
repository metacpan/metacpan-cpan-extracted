use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'OPTiMaDe::Filter',
	VERSION_FROM => 'lib/OPTiMaDe/Filter.pm',
	PREREQ_PM => {
		Parse::Yapp => 0,
		Scalar::Util => 0,
	},
	depend => { pm_to_blib => 'blib/lib/OPTiMaDe/Filter/Parser.pm' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		repository => {
			type => 'git',
			url  => 'https://github.com/Materials-Consortia/OPTiMaDe-Filter.git',
			web  => 'https://github.com/Materials-Consortia/OPTiMaDe-Filter',
		},
	},
);

sub MY::postamble {
<<'EOT'
blib/lib/OPTiMaDe/Filter/%.pm: %.yp
	mkdir --parents $(@D)
	yapp -v -m OPTiMaDe::Filter::Parser -o $@ $<
EOT
}
