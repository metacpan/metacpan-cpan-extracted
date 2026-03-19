# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 11;
use Regexp::Parser;

my $r = Regexp::Parser->new;
my $rx = '(?i:a)b(?i)c(?-i)d';

ok( $r->regex($rx), 'parse regex with flags' );
ok( my $w = $r->walker, 'walker created' );
while (my ($n, $d) = $w->()) {
  chomp(my $exp = <DATA>);
  my $got = join("\t", $d, $n->family, $n->type);
  my $vis = $n->visual;
  $got .= "\t$vis" if length $vis;
  is( $got, $exp, "node: $exp" );
}
is( scalar(<DATA>), "DONE\n", 'walker done' );

__DATA__
0	group	group	(?i:a)
1	exact	exactf	a
0	close	tail
0	exact	exact	b
0	flags	flags	(?i)
0	exact	exactf	c
0	flags	flags	(?-i)
0	exact	exact	d
DONE
