use 5.008_007;
use ExtUtils::MakeMaker;

use strict;
use warnings;

use SPVM::Builder::Util::API;

WriteMakefile(
    NAME              => 'SPVM::JSON',
    VERSION_FROM      => 'lib/SPVM/JSON.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl_5',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SPVM/JSON.pm', # retrieve abstract from module
       AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
    test => {TESTS => 't/*.t'},
    clean => {FILES => ".spvm_build"},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/Perl-SPVM-JSON.git',
                web  => 'https://github.com/yuki-kimoto/Perl-SPVM-JSON',
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
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('JSON');
  
  return $make_rule;
}

1;
