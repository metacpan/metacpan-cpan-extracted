use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'QuickTermChart::QuickTermChart',
  VERSION_FROM     => 'lib/QuickTermChart/QuickTermChart.pm',
  ABSTRACT         => 'QuickTermChart/QuickTermChart.pm',
  AUTHOR           => 'Shadkam Islam',
  #LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/quick_term_chart'],
  PREREQ_PM        => {
    'strict'          => 0,
    'warnings'        => 0,
    'DateTime'        => '0.37',
    'Term::ANSIColor' => 0,
    'Term::ReadKey'   => 0,
    'POSIX'           => 0,
    'Getopt::Long'    => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/shadkam/QuickTermChart.git',
              web  => 'https://github.com/shadkam/QuickTermChart',
          },
      }})
   : ()
  ),
);
