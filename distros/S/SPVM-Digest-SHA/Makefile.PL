use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;

WriteMakefile(
  NAME              => 'SPVM::Digest::SHA',
  VERSION_FROM      => 'lib/SPVM/Digest/SHA.pm',
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Digest/SHA.pm',
     AUTHOR         => 'USER_NAME<USER_MAIL>') : ()),
  test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
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
    no_index => {
      directory => ['perl_impl'],
    }
  },
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    # SPVM::Builder::Util::API is needed for Makefile.PL
    'SPVM'              => '0.9622',
  },
  PREREQ_PM => {
    
  },
  TEST_REQUIRES => {
    
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Digest::SHA');
  
  $make_rule .= qq|dynamic ::\n\tperl -e 'use Config;chdir "perl_impl" or die; system("$^X Makefile.PL && $Config{make}") == 0 or die';|;
  
  return $make_rule;
}

1;
