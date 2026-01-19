use v5;
use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Net::LibAsyncNS',
   configure_requires => {
      'ExtUtils::CChecker' => '0.05',
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => '0.4004', # test_requires
      'Module::Build::Using::PkgConfig' => 0,
   },
   requires => {
      'perl' => '5.020',
      'Exporter' => '5.57',
   },
   test_requires => {
      'Test2::V0' => '0.000149',
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->use_pkgconfig( "libasyncns",
   atleast_version => "0.6",
   alien           => "Alien::Libasyncns", # yes, capitalised differently
);

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

$build->push_extra_compiler_flags( @{ $cc->extra_compiler_flags } );

$build->create_build_script;
