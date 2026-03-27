use strict;
use warnings;

use Test::More tests => 77;
use Regexp::Parser;

my $r = Regexp::Parser->new;

#
# (?(DEFINE)...) — always-false condition for defining groups
#

my @define_rx = (
  q{(?(DEFINE)(?<digit>\d+))},
  q{(?(DEFINE)(?<a>\d+)(?<b>\w+))},
  q{(?(DEFINE)(?<helper>[a-z]+))},
);

for my $rx (@define_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

#
# (?(<name>)...) and (?('name')...) — named capture conditions
#

my @named_cond_rx = (
  q{(?<foo>bar)(?(<foo>)yes|no)},
  q{(?('foo')yes|no)},
);

for my $rx (@named_cond_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

#
# Round-trip: parse -> visual -> re-parse -> visual
#

my @roundtrip_rx = (
  q{(?(DEFINE)(?<d>\d+))},
  q{(?(<foo>)yes|no)},
  q{(?('foo')yes|no)},
  q{(?(DEFINE)(?<a>\d+)(?<b>\w+))},
);

for my $rx (@roundtrip_rx) {
  ok( $r->regex($rx), "roundtrip parse $rx" );
  my $v1 = $r->visual;
  ok( $r->regex($v1), "roundtrip re-parse $v1" );
  my $v2 = $r->visual;
  is( $v2, $v1, "roundtrip stable for $rx" );
}

#
# Rejection: non-DEFINE words should still fail
#

my @bad_rx = (
  q{(?(BAD)c|d)},
  q{(?(DEFINED)c|d)},
  q{(?(define)c|d)},
);

for my $rx (@bad_rx) {
  ok( !$r->regex($rx), "reject $rx" );
}

__DATA__
0	assertion	ifthen	(?(DEFINE)(?<digit>\d+))
1	groupp	define	(DEFINE)
1	branch	branch	(?<digit>\d+)
2	open	open1	(?<digit>\d+)
3	quant	plus	\d+
4	digit	digit	\d
2	close	close1
0	close	tail
DONE
0	assertion	ifthen	(?(DEFINE)(?<a>\d+)(?<b>\w+))
1	groupp	define	(DEFINE)
1	branch	branch	(?<a>\d+)(?<b>\w+)
2	open	open1	(?<a>\d+)
3	quant	plus	\d+
4	digit	digit	\d
2	close	close1
2	open	open2	(?<b>\w+)
3	quant	plus	\w+
4	alnum	alnum	\w
2	close	close2
0	close	tail
DONE
0	assertion	ifthen	(?(DEFINE)(?<helper>[a-z]+))
1	groupp	define	(DEFINE)
1	branch	branch	(?<helper>[a-z]+)
2	open	open1	(?<helper>[a-z]+)
3	quant	plus	[a-z]+
4	anyof	anyof	[a-z]
5	anyof_range	anyof_range	a-z
4	close	anyof_close
2	close	close1
0	close	tail
DONE
0	open	open1	(?<foo>bar)
1	exact	exact	bar
0	close	close1
0	assertion	ifthen	(?(<foo>)yes|no)
1	groupp	grouppn	(<foo>)
1	branch	branch	yes|no
2	exact	exact	yes
1	branch	branch
2	exact	exact	no
0	close	tail
DONE
0	assertion	ifthen	(?('foo')yes|no)
1	groupp	grouppn	('foo')
1	branch	branch	yes|no
2	exact	exact	yes
1	branch	branch
2	exact	exact	no
0	close	tail
DONE
