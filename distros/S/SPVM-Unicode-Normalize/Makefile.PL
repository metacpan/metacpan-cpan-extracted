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

}

my %configure_and_runtime_requires = (
  'SPVM' => '0.990042',
  'SPVM::Resource::Utf8proc' => '0.001',
);
WriteMakefile(
  NAME              => 'SPVM::Unicode::Normalize',
  VERSION_FROM      => 'lib/SPVM/Unicode/Normalize.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Unicode/Normalize.pm',
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Unicode-Normalize.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Unicode-Normalize',
      },
    },
  },
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
  },
  TEST_REQUIRES => {
  }
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Unicode::Normalize');
  }
  
  return $make_rule;
}

1;
