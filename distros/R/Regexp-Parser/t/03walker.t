# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 51;
use Regexp::Parser;

my $r = Regexp::Parser->new;
my $rx = '^a+b*?c{5,}d{3}$';

ok( $r->regex($rx), 'parse regex' );

for my $arg (-1, 0, 1, 2) {
  ok( my $w = $r->walker($arg), "walker($arg) created" );
  is( $w->(-depth), $arg, "walker depth is $arg" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker($arg) done" );
}

__DATA__
0	anchor	bol	^
0	quant	plus	a+
1	exact	exact	a
0	minmod	minmod	b*?
1	quant	star	b*
2	exact	exact	b
0	quant	curly	c{5,}
1	exact	exact	c
0	quant	curly	d{3}
1	exact	exact	d
0	anchor	eol	$
DONE
0	anchor	bol	^
0	quant	plus	a+
0	minmod	minmod	b*?
0	quant	curly	c{5,}
0	quant	curly	d{3}
0	anchor	eol	$
DONE
0	anchor	bol	^
0	quant	plus	a+
1	exact	exact	a
0	minmod	minmod	b*?
1	quant	star	b*
0	quant	curly	c{5,}
1	exact	exact	c
0	quant	curly	d{3}
1	exact	exact	d
0	anchor	eol	$
DONE
0	anchor	bol	^
0	quant	plus	a+
1	exact	exact	a
0	minmod	minmod	b*?
1	quant	star	b*
2	exact	exact	b
0	quant	curly	c{5,}
1	exact	exact	c
0	quant	curly	d{3}
1	exact	exact	d
0	anchor	eol	$
DONE
