use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Rinchi::Fortran::Preprocessor',
    VERSION_FROM      => 'lib/Rinchi/Fortran/Preprocessor.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Rinchi/Fortran/Preprocessor.pm', # retrieve abstract from module
       AUTHOR         => 'Brian M. Ames <bmames@apk.net>') : ()),
    LIBS              => ['-lfl -lpopt'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
);

sub MY::postamble {
  return "include make_rules.inc"
}
