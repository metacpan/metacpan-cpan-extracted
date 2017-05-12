use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new();

$cc->find_libs_for(
   diag => "cannot find library containing res_query(3)",
   libs => [ "", "resolv" ],
   source => <<'EOF' );
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>
int main(int argc, char *argv[]) {
   /* Ignore the result; we only care that we can compile and link this program */
   char answer[128];
   res_query("example.com", 0, 0, answer, sizeof answer);
   return 0;
}
EOF

my $build = $cc->new_module_build(
   module_name => 'Net::LibResolv',
   configure_requires => {
      'ExtUtils::CChecker' => 0,
      'Module::Build' => 0,
   },
   requires => {
      'Exporter' => '5.57',
   },
   build_requires => {
      'ExtUtils::CChecker' => 0,
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
