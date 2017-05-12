use 5.012;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Parse::ABNF',
  VERSION_FROM      => 'lib/Parse/ABNF.pm', # finds $VERSION
  PREREQ_PM         => {
    'Parse::RecDescent' => 0,
  },
  ($] >= 5.005 ?     
    (ABSTRACT_FROM  => 'lib/Parse/ABNF.pm', # retrieve abstract from module
     AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

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
         url  => 'https://github.com/hoehrmann/Parse-ABNF.git',
         web  => 'https://github.com/hoehrmann/Parse-ABNF',
      },
    },
  },
);
