use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use File::Temp();
use Getopt::Long 'GetOptions';

GetOptions(
  'meta' => \my $meta,
  'no-build-spvm-modules' => \my $no_build_spvm_modules,
);

if ($meta) {
  $no_build_spvm_modules = 1;
}

my %spvm_requires = ('SPVM' => '0.990155');
WriteMakefile(
  NAME              => 'SPVM::Resource::RE2',
  VERSION_FROM      => 'lib/SPVM/Resource/RE2.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Resource/RE2.pm',
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Resource-RE2.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Resource-RE2',
      },
    },
  },
  CONFIGURE_REQUIRES => {
    %spvm_requires,
  },
  PREREQ_PM         => {
    %spvm_requires,
  },
  NORECURS => 1,
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
  }
  
  return $make_rule;
}

1;
