use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use Getopt::Long 'GetOptions';

GetOptions(
  'meta' => \my $meta,
  'no-build-spvm-modules' => \my $no_build_spvm_modules,
);

if ($meta) {
  $no_build_spvm_modules = 1;
}

my %configure_and_runtime_requires = (
  'SPVM' => '0.9691',
);
WriteMakefile(
  NAME              => 'SPVM::Errno',
  VERSION_FROM      => 'lib/SPVM/Errno.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Errno.pm',
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
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
  },
  TEST_REQUIRES => {
    
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Errno');
  }
  
  return $make_rule;
}

1;
