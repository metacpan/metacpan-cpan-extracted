use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";
eval { ExtUtils::CChecker->VERSION( 0.04 ) } or
   die "OS unsupported - ExtUtils::CChecker too old; need at least 0.04";

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run(
   diag => "no PF_PACKET",
   source => <<'EOF' );
#include <sys/socket.h>
int family = PF_PACKET;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

# Some userland headers are sufficiently old that they don't have TPACKET_V2
# or the tpacket2_hdr structure. If this is the case we have little choice but
# to cheat a little and try to use the kernel ones instead.
chomp( my $uname_r = `uname -r` );

my @dirs = (
   [],
   [ "/lib/modules/$uname_r/source/include" ],
);

$cc->find_include_dirs_for(
   diag => "no PACKET_STATISTICS",
   dirs => \@dirs,
   source => <<'EOF' );
#include <linux/if_packet.h>
int origdev = PACKET_STATISTICS;
struct tpacket_stats stats;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

$cc->try_find_include_dirs_for(
   define => "HAVE_ORIGDEV",
   dirs => \@dirs,
   source => <<'EOF' );
#include <linux/if_packet.h>
int origdev = PACKET_ORIGDEV;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

$cc->try_find_include_dirs_for(
   define => "HAVE_TPACKET",
   dirs => \@dirs,
   source => <<'EOF' );
#include <linux/if_packet.h>
struct tpacket_hdr hdr;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

$cc->try_find_include_dirs_for(
   define => "HAVE_TPACKET2",
   dirs => \@dirs,
   source => <<'EOF' );
#include <linux/if_packet.h>
int pkttype = TPACKET_V2;
struct tpacket2_hdr hdr;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Socket::Packet',
   requires => {
      'Exporter' => '5.57',
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.04',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   build_requires => {
      'ExtUtils::CChecker' => 0,
      'IO::Socket::INET' => 0,
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
