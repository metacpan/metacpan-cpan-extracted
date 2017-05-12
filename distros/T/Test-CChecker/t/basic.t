use strict;
use warnings;
use Test::More tests => 4;
use Test::CChecker;

my $r;

$r = compile_run_ok <<EOF, "basic compile test";
int main(int argc, char *argv[]) { return 0; }
EOF

ok $r, 'returns okay';

$r = compile_run_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => <<EOF }, "define test";
#if ! FOO_BAR_BAZ
#include <stdio.h>
#endif
int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  printf("NOT DEFINED");
  return 1;
#endif
}
EOF

ok $r, 'returns ok';
