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
  'SPVM' => '0.973',
);
WriteMakefile(
  NAME              => 'SPVM::Digest::SHA',
  VERSION_FROM      => 'lib/SPVM/Digest/SHA.pm',
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Digest/SHA.pm',
     AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
  test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Digest-SHA.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Digest-SHA',
      },
    },
    no_index => {
      directory => ['perl_impl'],
    }
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
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Digest::SHA');
  }
  
  # Compile Perl's Digest::MD5 for tests.
  $make_rule .= qq|dynamic ::\n\tperl -e "use Config;chdir qq(perl_impl) or die; system(qq(perl Makefile.PL)) == 0 or die;system(qq($Config{make})) == 0 or die;";|;
  
  return $make_rule;
}

1;
