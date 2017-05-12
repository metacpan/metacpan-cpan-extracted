use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
	package MY;
	shift->SUPER::postamble . <<'MAKE';
dist : README

README : InKey.pm
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

MAKE
}

WriteMakefile(
    'NAME'	=> 'Term::InKey',
    'VERSION_FROM' => 'InKey.pm', # finds $VERSION
    'dist' => {'COMPRESS' => 'gzip --best --force'},
);
