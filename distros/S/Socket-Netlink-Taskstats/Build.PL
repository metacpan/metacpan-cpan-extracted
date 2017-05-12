use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new;

$cc->assert_compile_run(
   diag => "no taskstats.h",
   source => <<'EOF' );
#include <linux/taskstats.h>
int cmd = TASKSTATS_CMD_GET;
int main(int argc, char *argv[]) {
  return 0;
}
EOF

# Some userland headers are sufficiently old that we have little choice but to
# cheat a little and try to use the kernel ones instead.
chomp( my $uname_r = `uname -r` );

$cc->find_include_dirs_for(
   diag => "no taskstats.h for TASKSTATS_VERSION >= 7",
   dirs => [ [], [ "/lib/modules/$uname_r/build/include" ] ],
   source => <<'EOF' );
#include <sys/socket.h>
#include <linux/taskstats.h>
int main(int argc, char *argv[]) {
  if(TASKSTATS_VERSION >= 7)
    return 0;
  return 1;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Socket::Netlink::Taskstats',
   requires => {
      'Exporter' => '5.57',
      'Socket::Netlink' => '0.04',
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.02',
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
   },
   build_requires => {
      'ExtUtils::CChecker' => '0.02',
      'ExtUtils::H2PM' => '0.06',
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
