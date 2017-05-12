use strict;
use warnings;
use Test::More tests => 4;
use Test::CChecker;

my $r;

$r = compile_ok <<EOF, "basic compile only test";
extern int foo(void);
int main(int argc, char *argv[]) { return foo(); }
EOF

ok $r, 'returns okay';

$r = compile_ok { extra_compiler_flags => ['-DFOO_BAR_BAZ=1'], source => <<EOF }, "define test";
int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  this constitutes a synatax error
#endif
}
EOF

ok $r, 'returns ok';
