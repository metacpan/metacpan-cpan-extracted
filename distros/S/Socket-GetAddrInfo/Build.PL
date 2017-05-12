use strict;
use warnings;

use Module::Build;
use ExtUtils::CBuilder;

my %extra_requires;
my $extra_compiler_flags;
my $extra_linker_flags;

my $build_xs = 1;

grep { $_ eq "--pp" } @ARGV and $build_xs = 0;

if( $ENV{PERL_SOCKET_GETADDRINFO_NO_BUILD_XS} ) {
   print "PERL_SOCKET_GETADDRINFO_NO_BUILD_XS specified in environment; disabling XS implementation\n";
   $build_xs = 0;
}

# As of Perl 5.13.9, core's Socket now contains getaddrinfo, getnameinfo, and
# all the associated constants.
if( $build_xs and eval { require Socket and defined &Socket::getaddrinfo and defined &Socket::NIx_NOHOST } ) {
   print "&Socket::getaddrinfo exists so no need to build XS implementation\n";
   $build_xs = 0;

   $extra_requires{"Socket"} = $Socket::VERSION;
}

if( $build_xs and not ExtUtils::CBuilder->new->have_compiler ) {
   print "No C compiler is available so cannot build XS implementation\n";
   $build_xs = 0;
}

if( $build_xs ) {
   eval { require ExtUtils::CChecker; 1 } or
      die "OS unsupported - missing ExtUtils::CChecker";
   eval { ExtUtils::CChecker->VERSION( 0.06 ) } or
      die "OS unsupported - ExtUtils::CChecker too old; need at least 0.06";

   my $cc = ExtUtils::CChecker->new(
      defines_to => "socket-gai-config.h",
   );

   print "\nDetecting if libc supports getaddrinfo()...\n";

   my $headers = <<'EOF';
#include <stdlib.h>
#include <stdio.h>
#ifdef WIN32
#undef WINVER
#define WINVER          0x0501
#ifdef __GNUC__
# define USE_W32_SOCKETS
#endif
#include <winsock2.h>
/* We need to include ws2tcpip.h to get the IPv6 definitions.
 * It will in turn include wspiapi.h.  Later versions of that
 * header in the Windows SDK generate C++ template code that
 * can't be compiled with VC6 anymore.  The _WSPIAPI_COUNTOF
 * definition below prevents wspiapi.h from generating this
 * incompatible code.
 */
# define _WSPIAPI_COUNTOF(_Array) (sizeof(_Array) / sizeof(_Array[0]))
# undef UNICODE
#include <ws2tcpip.h>
#ifndef NI_NUMERICSERV
#error Microsoft Platform SDK (Aug. 2001) or later required.
#endif
#ifdef _MSC_VER
# pragma comment(lib, "Ws2_32.lib")
#endif
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif
EOF

   $cc->try_find_libs_for(
      define => "HAS_GETADDRINFO",
      # Solaris et.al. use -lsocket or -lsocket -lnsl
      libs => $^O eq 'MSWin32'
                ? [ "", "ws2_32" ]
                : [ "", "socket", "socket nsl" ],
      source => $headers . <<'EOF' );
int main(int argc, char *argv[]) {
  struct addrinfo hints = { 0 };
  struct addrinfo *res;
  int rc;
#ifdef _WIN32
  WSADATA wsadata;
  rc = WSAStartup(MAKEWORD(2, 0), &wsadata);
  if (rc != 0) {
    printf("WSAStartup() failed: %d\n", rc);
    return 1;
  }
#endif
  hints.ai_socktype = SOCK_STREAM;
  rc = getaddrinfo("127.0.0.1", "80", &hints, &res);
  if (rc != 0) {
    printf("getaddrinfo() failed: %d\n", rc);
    return 1;
  }
  freeaddrinfo(res);
  return 0;
}
EOF

   print "Detecting if sockaddr has sa_len field...\n";

   $cc->try_compile_run(
      define => "HAS_SOCKADDR_SA_LEN",
      source => $headers . <<'EOF' );
int main(int argc, char *argv[]) {
   struct sockaddr sa;
   sa.sa_len = 0;
   return 0;
}
EOF

   $extra_requires{"XSLoader"} = 0;
   $extra_compiler_flags = $cc->extra_compiler_flags;
   $extra_linker_flags = $cc->extra_linker_flags;
}

my $build = Module::Build->new(
   module_name => 'Socket::GetAddrInfo',
   dist_version_from => 'lib/Socket/GetAddrInfo.pm',
   requires => {
      'Exporter' => '5.57',
      %extra_requires,
   },
   configure_requires => {
      'ExtUtils::CBuilder' => 0,
      'ExtUtils::CChecker' => '0.06',
      'Module::Build' => 0,
   },
   build_requires => {
      'ExtUtils::CBuilder' => 0,
      'ExtUtils::CChecker' => '0.06',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Scalar::Util' => 0,
      'Test::More' => 0,
   },
   extra_compiler_flags => $extra_compiler_flags,
   extra_linker_flags => $extra_linker_flags,
   ( $build_xs ? () : ( xs_files => {} ) ),
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
