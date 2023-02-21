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
        url  => 'https://github.com/yuki-kimoto/SPVM-Digest-MD5.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Digest-MD5',
      },
    },
    no_index => {
      directory => [qw/perl_impl/],
    }
  },
  NORECURS => 1,
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Digest::MD5');
  }
  
  # Compile Perl's Digest::MD5 for tests.
  $make_rule .= qq|dynamic ::\n\tperl -e "use Config;chdir qq(perl_impl) or die; system(qq(perl Makefile.PL)) == 0 or die;system(qq($Config{make})) == 0 or die;";|;
  
  return $make_rule;
}

1;
