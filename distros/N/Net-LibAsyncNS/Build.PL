use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::PkgConfig; } or
   die "OS unsupported - no ExtUtils::PkgConfig\n";

eval { ExtUtils::PkgConfig->find("libasyncns"); } or
   die "OS unsupported - pkg-config cannot find libasyncns\n";

my $version = ExtUtils::PkgConfig->modversion("libasyncns");
$version >= 0.6 or die "OS unsupported - libasyncns too old ($version)\n";

my $cflags = ExtUtils::PkgConfig->cflags("libasyncns");
my $libs   = ExtUtils::PkgConfig->libs("libasyncns");

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";
eval { ExtUtils::CChecker->VERSION( 0.05 ) } or
   die "OS unsupported - ExtUtils::CChecker too old; need at least 0.05";

my $cc = ExtUtils::CChecker->new();

$cc->try_compile_run(
   define => "HAVE_SOCKADDR_SA_LEN",
   source => <<'EOF' );
#include <stdlib.h>
#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#endif
int main(int argc, char *argv[]) {
   struct sockaddr sa;
   sa.sa_len = 0;
   return 0;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Net::LibAsyncNS',
   extra_compiler_flags => [ split( m/ /, $cflags ) ],
   extra_linker_flags   => [ split( m/ /, $libs ) ],
   configure_requires => {
      'ExtUtils::CChecker' => '0.05',
      'ExtUtils::PkgConfig' => 0,
   },
   requires => {
      'Exporter' => '5.57',
   },
   build_requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Test::More' => 0,
      'Test::Identity' => 0,
      'Test::Refcount' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
