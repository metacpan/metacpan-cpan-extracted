use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Perl::AfterFork',
    VERSION_FROM      => 'lib/Perl/AfterFork.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Perl/AfterFork.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    dist              => {
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
README: lib/Perl/AfterFork.pm mk_README.sh
	./mk_README.sh
EOF
}
