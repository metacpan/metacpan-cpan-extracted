use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'OPTiMaDe::FilterParser',
	VERSION_FROM => 'lib/OPTiMaDe/FilterParser.pm',
	PREREQ_PM => {
		Parse::Yapp => 0,
		Scalar::Util => 0,
	},
);

sub MY::postamble {
<<'EOT'
lib/OPTiMaDe/%.pm: %.yp
	yapp -v -m OPTiMaDe::FilterParser -o $@ $<
EOT
}
