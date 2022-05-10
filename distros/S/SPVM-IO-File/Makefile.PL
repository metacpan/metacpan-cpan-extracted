use 5.008_007;
use ExtUtils::MakeMaker;

use strict;
use warnings;

use SPVM::Builder::Util::API;

WriteMakefile(
    NAME              => 'SPVM::IO::File',
    VERSION_FROM      => 'lib/SPVM/IO/File.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl_5',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SPVM/IO/File.pm', # retrieve abstract from module
       AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
    test => {TESTS => 't/*.t'},
    clean => {FILES => ".spvm_build"},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/Perl-SPVM-IO-File.git',
                web  => 'https://github.com/yuki-kimoto/Perl-SPVM-IO-File',
            },
        },
    },
    PREREQ_PM => {
        'SPVM'              => '0.9500',
    },
);

# Add Build shared library make rule
sub MY::postamble {

  my $make_rule = '';
  
  # Native compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('IO::File');

  # Precompile compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('IO::File');
  
  return $make_rule;
}

1;
