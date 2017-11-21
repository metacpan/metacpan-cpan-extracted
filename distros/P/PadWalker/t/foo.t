use strict;
use PadWalker;
use Data::Dumper;

print "1..6\n";

chdir "t";
require "./bar.pl";
do "./baz.pl";

my $nono;

sub foo {
  my $inner = "You shouldn't see this one";
  PadWalker::peek_my(1);
}
