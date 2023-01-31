use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;

my %configure_and_runtime_requires = (
  'SPVM' => '0.9688',
  'SPVM::Sys' => '0.35'
);
WriteMakefile(
  NAME              => 'SPVM::Cwd',
  VERSION_FROM      => 'lib/SPVM/Cwd.pm',
  PREREQ_PM         => {
    'SPVM::Sys' => '0.27',
  }, # e.g., Module::Name => 1.1
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Cwd.pm',
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Cwd.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Cwd',
      },
    },
  },
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  return $make_rule;
}

1;
