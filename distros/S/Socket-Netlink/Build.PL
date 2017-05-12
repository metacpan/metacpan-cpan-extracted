use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run(
   diag => "no PF_NETLINK",
   source => <<'EOF' );
#include <stdio.h>
#include <sys/socket.h>
int main(int argc, char *argv[]) {
  printf("PF_NETLINK is %d\n", PF_NETLINK);
  return 0;
}
EOF

# Some userland headers are sufficiently old that they don't have NLA_HDRLEN
# or struct nlattr. If this is the case we have little choice but to cheat a
# little and try to use the kernel ones instead.
chomp( my $uname_r = `uname -r` );

$cc->find_include_dirs_for(
   diag => "no NLA_HDRLEN",
   dirs => [ [], [ "/lib/modules/$uname_r/build/include" ] ],
   source => <<'EOF' );
#include <sys/socket.h>
#include <linux/netlink.h>
struct nlattr nla;
int len = NLA_HDRLEN;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Socket::Netlink',
   requires => {
      'Exporter' => '5.57',
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.02',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   build_requires => {
      'ExtUtils::H2PM' => '0.07',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   test_requires => {
      'Test::HexString' => 0,
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
