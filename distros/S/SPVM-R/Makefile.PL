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

unless ($meta) {
  # Do something such as environment check.
}

my %configure_and_runtime_requires = ('SPVM' => '0.990006');
WriteMakefile(
  NAME => 'SPVM::R',
  VERSION_FROM => 'lib/SPVM/R.pm',
  LICENSE => 'mit',
  ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/SPVM/R.pm',
     AUTHOR => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
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
      directory => [],
    }
  },
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
    'SPVM::Math' => '1.002',
    'SPVM::Time::Piece' => '0.003',
    'SPVM::Sys' => '0.525',
  },
  TEST_REQUIRES => {
    
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    
    local @INC = ('lib', @INC);
    
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('R::OP::Matrix::Float');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('R::OP::Matrix::FloatComplex');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('R::OP::Matrix::Double');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('R::OP::Matrix::DoubleComplex');
    
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::Int');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::Long');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::Float');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::Double');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::FloatComplex');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('R::OP::DoubleComplex');
  }
  
  return $make_rule;
}

1;
