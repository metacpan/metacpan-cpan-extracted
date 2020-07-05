use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Stance::Vault',
  VERSION_FROM     => 'lib/Stance/Vault.pm',
  ABSTRACT_FROM    => 'lib/Stance/Vault.pm',
  AUTHOR           => 'James Hunt',
  LICENSE          => 'mit',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => [],
  PREREQ_PM        => {
    'strict'         => 0,
    'warnings'       => 0,
    'JSON'           => '0',
    'LWP::UserAgent' => '0',
    'HTTP::Request'  => '0',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/jhunt/perl-Stance-Vault.git',
              web  => 'https://github.com/jhunt/perl-Stance-Vault',
          },
      }})
   : ()
  ),
);
