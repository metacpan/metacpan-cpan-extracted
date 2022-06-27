use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;

WriteMakefile(
  NAME              => 'SPVM::Time::Local',
  VERSION_FROM      => 'lib/SPVM/Time/Local.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Time/Local.pm',
     AUTHOR         => 'USER_NAME<USER_MAIL>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => '',
        web  => '',
      },
    },
  },
  # SPVM::Builder::Util::API is needed for Makefile.PL
  CONFIGURE_REQUIRES => {
    'SPVM'              => '0.9610',
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Time::Local');
  
  
  return $make_rule;
}

1;
