use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'OPTiMaDe::FilterParser',
	VERSION_FROM => 'lib/OPTiMaDe/FilterParser.pm',
);

sub MY::postamble {
<<'EOT'
lib/OPTiMaDe/%.pm: %.yp
	yapp -v -m OPTiMaDe::FilterParser -o $@ $<
EOT
}
