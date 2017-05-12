use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME         => 'Morale',
  VERSION_FROM => 'lib/Morale.pm',

  PREREQ_PM => {
    Tk => 0,
  },

  AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
  ABSTRACT     => 'Morale statistics',
  EXE_FILES    => [ qw(script/tkmorale) ],
  dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);

