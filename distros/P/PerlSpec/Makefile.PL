use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'PerlSpec',
  VERSION_FROM      => 'lib/PerlSpec.pm',
  PREREQ_PM         => {
    version  => 0.77
  },
  AUTHOR            => 'Matthew Boston <matthew.boston@gmail.com>'
);
