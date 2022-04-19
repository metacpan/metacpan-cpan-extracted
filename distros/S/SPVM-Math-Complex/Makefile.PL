use 5.008_007;
use ExtUtils::MakeMaker;

use strict;
use warnings;
use Config;

use SPVM::Builder::Util::API;

# Check supported environment
{
  # Currently SPVM doesn't support Alpine Linux
  
  
  my $myuname = $Config{myuname};
  # Free BSD myyname examples
  # "freebsd www3301.sakura.ne.jp 9.1-release-p24 freebsd 9.1-release-p24 #0: thu feb 5 10:03:29 jst 2015 root@www3304.sakura.ne.jp:usrobjusrsrcsyssakura17 amd64"
  # "freebsd cloud2.bbbike.org 14.0-current freebsd 14.0-current #1 main-n249154-312f5f8a4fb9: sat sep 4 21:10:11 utc 2021 root@cloud2.bbbike.org:usrobjusrhomeprojectsfreebsdamd64.amd64sysgeneric amd64"
  if ($myuname =~ /\bfreebsd\b/i) {
    my ($major_version, $minor_version);
    if ($myuname =~ /\bfreebsd\s+(\d+)\.(\d+)/) {
      $major_version = $1;
      $minor_version = $2;
    }
    if ($major_version < 12) {
      warn "SPVM::Math::Complex only supports FreeBSD 12+ because old FreeBSD doesn't support C99 complex math functions correctly. The current FreeBSD version is $major_version.$minor_version";
      die "OS unsupported\n";
    }
  }
}

WriteMakefile(
    NAME              => 'SPVM::Math::Complex',
    VERSION_FROM      => 'lib/SPVM/Math/Complex.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl_5',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SPVM/Math/Complex.pm', # retrieve abstract from module
       AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
    test => {TESTS => 't/*.t'},
    clean => {FILES => ".spvm_build"},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/SPVM-Math-Complex.git',
                web  => 'https://github.com/yuki-kimoto/SPVM-Math-Complex',
            },
        },
    },
    # SPVM::Builder::Util::API is needed for Makefile.PL
    CONFIGURE_REQUIRES => {
        'SPVM'              => '0.9511',
    },
);

# Add Build shared library make rule
sub MY::postamble {

  my $make_rule = '';
  
  # Native compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Math::Complex');

  # Native compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('Math::Complex');
  
  return $make_rule;
}

1;
