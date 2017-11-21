use PadWalker 'var_name';

use strict;
use warnings;
no warnings 'misc';

chdir "t";

print "1..8\n";

my $foo;
my $r = \$foo;
my $foo;

print (var_name(0, $r) eq '$foo' ? "ok 1\n" : "not ok 1\n");
print (var_name(0, \$foo) eq '$foo' ? "ok 2\n" : "not ok 2\n");

foo();

sub foo {
  my $r = \$foo;
  print (var_name(1, $r) eq '$foo' ? "ok 3\n" : "not ok 3\n");
}

my $closure;
{
  my $aaa;
  $closure = sub {
    \$aaa;
  };
}

print (var_name($closure, $closure->()) eq '$aaa' ? "ok 4\n" : "not ok 4\n");

require "./vn-inc-1.pl";
