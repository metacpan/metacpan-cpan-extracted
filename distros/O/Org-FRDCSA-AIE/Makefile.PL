use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Org::FRDCSA::AIE',
  VERSION_FROM     => 'lib/Org/FRDCSA/AIE.pm',
  # ABSTRACT_FROM    => 'lib/Org/FRDCSA/AIE.pm',
  AUTHOR           => 'Andrew Dougherty',
  LICENSE          => 'gpl_3',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/aie'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'DateTime' => '0.37',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/aindilis/aie.git',
              web  => 'https://github.com/aindilis/aie',
          },
      }})
   : ()
  ),
);
