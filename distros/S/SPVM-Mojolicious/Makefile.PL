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

my %configure_and_runtime_requires = ('SPVM' => '0.990080');
WriteMakefile(
  NAME => 'SPVM::Mojolicious',
  VERSION_FROM => 'lib/SPVM/Mojolicious.pm',
  LICENSE => 'mit',
  ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/SPVM/Mojolicious.pm',
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
        url  => 'https://github.com/yuki-kimoto/SPVM-Mojolicious.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Mojolicious',
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
    'SPVM::FindBin' => '0.035',
    'SPVM::Time::HiRes' => '0.005',
    'SPVM::IO::Socket::SSL' => '0.010',
    'SPVM::Math' => '1.006',
  },
  TEST_REQUIRES => {
    
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    
    local @INC = ('lib', @INC);
    
    
    
  }
  
  return $make_rule;
}

1;
