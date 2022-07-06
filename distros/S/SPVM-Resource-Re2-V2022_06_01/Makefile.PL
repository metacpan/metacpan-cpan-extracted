use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;
use SPVM::Builder::Config;
use File::Temp();

# Check supported environment
{
  # Need a compiler supporting c++11
  my $config = SPVM::Builder::Config->new_cpp(file_optional => 1);
  my $cc = $config->cc;
  
  my $tmp_dir = File::Temp->newdir;
  
  unless (system("$cc -o $tmp_dir/cpp11_check.o --std=c++11 t/support/cpp11_check.cpp") == 0) {
    warn "Need a compiler supporting c++11\n";
    die "OS unsupported\n";
  }
}

WriteMakefile(
  NAME              => 'SPVM::Resource::Re2::V2022_06_01',
  VERSION_FROM      => 'lib/SPVM/Resource/Re2/V2022_06_01.pm',
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  LICENSE           => 'perl_5',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Resource/Re2/V2022_06_01.pm',
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
  # SPVM::Builder::Util::API is needed for Makefile.PL
  CONFIGURE_REQUIRES => {
    'SPVM'              => '0.9614',
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  
  
  
  return $make_rule;
}

1;
