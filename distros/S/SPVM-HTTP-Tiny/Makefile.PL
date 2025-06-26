use v5.20.3;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use Getopt::Long 'GetOptions';

GetOptions(
  'meta' => \my $meta,
  'no-build-spvm-classes' => \my $no_build_spvm_classes,
);

if ($meta) {
  $no_build_spvm_classes = 1;
}

unless ($meta) {
  # Do something such as environment check.
}

my %configure_and_runtime_requires = ('SPVM' => '0.990074');

WriteMakefile(
  NAME              => 'SPVM::HTTP::Tiny',
  VERSION_FROM           => 'lib/SPVM/HTTP/Tiny.pm',
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/HTTP/Tiny.pm',
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com') : ()),
  test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-HTTP-Tiny.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-HTTP-Tiny',
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
    'SPVM::IO' => '0.211',
    'SPVM::Regex' => '0.246',
    'SPVM::Mozilla::CA' => '0.001',
    'SPVM::File::Temp' => '0.021',
    'SPVM::Time::Piece' => '0.003',
    'SPVM::Time::Local' => '0.112',
    'SPVM::File::Temp' => '0.026',
    'SPVM::File::Copy' => '0.022',
    'SPVM::Digest::SHA' => '0.065',
    'SPVM::MIME::Base64' => '1.003',
    'SPVM::JSON' => '1.002',
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_classes) {
    require SPVM::Builder::Util::API;
    
    
    
  }
  
  return $make_rule;
}

1;
