use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'OPTiMaDe::Filter',
	VERSION_FROM => 'lib/OPTiMaDe/Filter.pm',
	PREREQ_PM => {
		Parse::Yapp => 0,
		Scalar::Util => 0,
	},
);

sub MY::postamble {
<<'EOT'
lib/OPTiMaDe/Filter/%.pm: %.yp
	yapp -v -m OPTiMaDe::Filter::Parser -o $@ $<
EOT
}
