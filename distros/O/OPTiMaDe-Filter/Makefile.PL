use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'OPTiMaDe::Filter',
	VERSION_FROM => 'lib/OPTiMaDe/Filter.pm',
	PREREQ_PM => {
		Parse::Yapp => 0,
		Scalar::Util => 0,
	},
	depend => { pm_to_blib => 'lib/OPTiMaDe/Filter/Parser.pm' },
);

sub MY::postamble {
<<'EOT'
lib/OPTiMaDe/Filter/%.pm: %.yp
	yapp -v -m OPTiMaDe::Filter::Parser -o $@ $<
EOT
}
