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

my %configure_and_runtime_requires = ('SPVM' => '0.990084', 'SPVM::Resource::Zlib' => '1.003');
WriteMakefile(
  NAME => 'SPVM::Compress::Raw::Zlib',
  VERSION_FROM => 'lib/SPVM/Compress/Raw/Zlib.pm',
  LICENSE => 'mit',
  ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/SPVM/Compress/Raw/Zlib.pm',
     AUTHOR => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => {
      version => 2,
      # release_status => 'stable', # stable, testing, or unstable
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Compress-Raw-Zlib.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Compress-Raw-Zlib',
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
    'SPVM::Regex' => '0.248',
  },
  TEST_REQUIRES => {
    
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    
    local @INC = ('lib', @INC);
    
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Compress::Raw::Zlib');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Compress::Raw::Zlib::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Compress::Raw::Zlib::Deflate');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Compress::Raw::Zlib::Inflate');
    
  }
  
  return $make_rule;
}

1;
