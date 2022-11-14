use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;

WriteMakefile(
  NAME              => 'SPVM::Digest::MD5',
  VERSION_FROM      => 'lib/SPVM/Digest/MD5.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Digest/MD5.pm',
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
    'SPVM'              => '0.9661',
  },
  NORECURS => 1,
  META_MERGE   => {
      no_index => {
          directory => [qw/perl_impl/],
      }
  }
);

sub MY::postamble {

  my $make_rule = '';
  
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Digest::MD5');
  
  $make_rule .= qq|dynamic ::\n\tperl -e 'use Config;chdir "perl_impl" or die; system("$^X Makefile.PL && $Config{make}") == 0 or die';|;
  
  return $make_rule;
}

1;
