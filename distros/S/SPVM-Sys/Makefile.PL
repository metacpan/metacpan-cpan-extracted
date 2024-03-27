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

# Check supported environment
{
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
    unless ($major_version >= 10) {
      warn "SPVM::Sys only supports FreeBSD 10+ because the following tests are hard to fix for us. http://www.cpantesters.org/cpan/report/b26888fa-55bd-11ed-9ef0-b2246e8775ea";
      die "OS unsupported\n";
    }
  }
  elsif ($myuname =~ /\bopenbsd\b/i) {
    warn "SPVM::Sys doesn't supports OpenBSD because the following tests are hard to fix for us. http://www.cpantesters.org/cpan/report/fa34e08c-5cf9-11ed-aba6-9a79f339625c";
    die "OS unsupported\n";
  }
}

# http://www.cpantesters.org/cpan/report/b26888fa-55bd-11ed-9ef0-b2246e8775ea

my %configure_and_runtime_requires = (
  'SPVM' => '0.989060',
  'SPVM::Resource::SocketUtil' => '1.001',
);
WriteMakefile(
  NAME              => 'SPVM::Sys',
  VERSION_FROM      => 'lib/SPVM/Sys.pm',
  LICENSE           => 'mit',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/SPVM/Sys.pm',
     AUTHOR         => 'USER_NAME<USER_MAIL>') : ()),
  test => {TESTS => 't/*.t'},
  clean => {FILES => ['.spvm_build', 't/.spvm_build']},
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/yuki-kimoto/SPVM-Sys.git',
        web  => 'https://github.com/yuki-kimoto/SPVM-Sys',
      },
      bugtracker => {
        web => "https://github.com/yuki-kimoto/SPVM-Sys/issues",
      },
    },
  },
  CONFIGURE_REQUIRES => {
    %configure_and_runtime_requires,
  },
  PREREQ_PM         => {
    %configure_and_runtime_requires,
    'SPVM::Errno' => '0.06',
  },
  TEST_REQUIRES => {
  }
);

sub MY::postamble {
  
  my $make_rule = '';
  
  unless ($no_build_spvm_modules) {
    require SPVM::Builder::Util::API;
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_precompile('Sys');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Windows');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::FileStream');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::DirStream');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Dirent');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Flock');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Process');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Process::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User::Passwd');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User::Group');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Errno');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Addrinfo');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::AddrinfoLinkedList');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Sockaddr');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Sockaddr::In');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Sockaddr::In6');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Sockaddr::Un');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Sockaddr::Storage');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::In_addr');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::In6_addr');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Ipv6_mreq');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Ip_mreq_source');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Ip_mreq');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Timeval');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Timespec');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Timezone');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Itimerval');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Tm');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Tms');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Utimbuf');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Select');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Select::Fd_set');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Poll');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Poll::PollfdArray');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Ioctl');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Ioctl::Constant');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Signal');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Signal::Handler');
    $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Signal::Constant');
  }
  
  return $make_rule;
}

1;
