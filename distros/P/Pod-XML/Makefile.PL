use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
  'NAME'	=> 'Pod::XML',
  'VERSION_FROM' => 'lib/Pod/XML.pm', # finds $VERSION
  'EXE_FILES' => [ 'scripts/pod2xml' ],
  'PREREQ_PM' => {
    Pod::Parser => 1.0,
    Test::File::Contents => 0,
    Test::More => 0,
    IO::Scalar => 0,
  },
);
