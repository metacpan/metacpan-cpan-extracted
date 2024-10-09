use v5.20.3;
use ExtUtils::MakeMaker;

use strict;
use warnings;

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
  'SPVM' => '0.989040',
);

WriteMakefile(
  NAME              => 'SPVM::IO',
  VERSION_FROM      => 'lib/SPVM/IO.pm', # finds $VERSION
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/IO.pm', # retrieve abstract from module
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ".spvm_build"},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-IO.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-IO',
      },
    },
  },
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
    'SPVM::Sys' => '0.524',
    'SPVM::Math' => '0.11',
    'SPVM::Go' => '0.005',
  },
);

# Add Build shared library make rule
sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
  }
  
  return $make_rule;
}

1;
