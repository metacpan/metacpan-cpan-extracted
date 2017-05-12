use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl::AtEndOfScope',
    VERSION_FROM      => 'lib/Perl/AtEndOfScope.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl/AtEndOfScope.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>') : ()),
    dist              => {
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
COMPRESS = gzip -9f

README: lib/Perl/AtEndOfScope.pm mk_README.sh
	./mk_README.sh

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Perl-AtEndOfScope.spec
	rpmbuild -ba perl-Perl-AtEndOfScope.spec
EOF
}
