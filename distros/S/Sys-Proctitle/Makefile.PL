use 5.008;

# prevent automatic testing on non-linux systems
BEGIN {$^O eq 'linux' or exit 0;}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::Proctitle',
    VERSION_FROM      => 'lib/Sys/Proctitle.pm', # finds $VERSION
    PREREQ_PM         => {
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sys/Proctitle.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>') : ()),
    LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    clean             => {
			  FILES => "libsetproctitle/*o",
			 },
    depend            => {
			  '$(INST_DYNAMIC)' => 'setproctitle',
			 },
    dist              => {
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
setproctitle:
	cd libsetproctitle && make install

.PHONY: setproctitle

README: lib/Sys/Proctitle.pm mk_README.sh
	./mk_README.sh

COMPRESS = gzip -9f

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Sys-Proctitle.spec
	rpmbuild -ba perl-Sys-Proctitle.spec
EOF
}
