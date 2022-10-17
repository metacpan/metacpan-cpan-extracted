use 5.008_007;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use SPVM::Builder::Util::API;

WriteMakefile(
  NAME              => 'SPVM::Sys',
  VERSION_FROM      => 'lib/SPVM/Sys.pm',
  LICENSE           => 'perl_5',
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
  # SPVM::Builder::Util::API is needed for Makefile.PL
  CONFIGURE_REQUIRES => {
    'SPVM'              => '0.9654',
  },
  PREREQ_PM         => {
    'SPVM::Errno' => '0.06',
  },
);

sub MY::postamble {

  my $make_rule = '';
  
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Constant');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::FileStream');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::DirStream');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Dirent');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Utimbuf');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::Flock');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::IO::PollfdArray');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Process');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Process::Constant');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User::Passwd');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::User::Group');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Constant');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::Addrinfo');
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Socket::AddrinfoLinkedList');
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
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native('Sys::Time::Tms');
  
  return $make_rule;
}

1;
