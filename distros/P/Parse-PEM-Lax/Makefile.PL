use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Parse::PEM::Lax',
  VERSION_FROM      => 'lib/Parse/PEM/Lax.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
  },
  ABSTRACT_FROM     => 'lib/Parse/PEM/Lax.pm',
  AUTHOR            => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
  LICENSE           => 'perl',

  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },

  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Parse-PEM-Lax.git',
         web  => 'https://github.com/hoehrmann/Parse-PEM-Lax',
      },
    },
  },
);
