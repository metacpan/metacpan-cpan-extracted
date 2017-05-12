use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'TX',
    VERSION_FROM      => 'lib/TX.pm', # finds $VERSION
    PREREQ_PM         => {
			  'Text::Template::Library' => 0.02,
			 }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/TX.pm', # retrieve abstract from module
    AUTHOR            => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
    dist              => {
			  COMPRESS => 'gzip -9f',
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-TX.spec
	rpmbuild -ba perl-TX.spec
EOF
}
