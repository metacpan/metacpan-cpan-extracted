
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all);
use Scalar::Util qw(refaddr);

plan tests => 18;

my $v = vector([1 .. 7]);
my $m = mean($v);
my $V = var($v);
my $s = stddev($v);

ok( $m, 4 ); # NOTE: oddly, the mean and variance of 1..7
ok( $V, 4 ); #   are both 4
ok( $s, 2 ); # and sqrt(4) is 2

ok( refaddr($v->{c}{mean}),     refaddr($m) );
ok( refaddr($v->{c}{variance}), refaddr($V) );
ok( refaddr($v->{c}{stddev}),   refaddr($s) );

ok( refaddr($m->{v}),    refaddr($v) );
ok( refaddr($V->{v}),    refaddr($v) );
ok( refaddr($s->{V}{v}), refaddr($v) );

ok( refaddr($V->{m}),    refaddr($m) );
ok( refaddr($s->{V}),    refaddr($V) );
ok( refaddr($s->{V}{m}), refaddr($m) );

undef $s;
ok( $s, undef );
ok( $v->{c}{stddev}, undef );

undef $V;
ok( $V, undef );
ok( $v->{c}{variance}, undef );

undef $m;
ok( $m, undef );
ok( $v->{c}{mean}, undef );

sub sum {
    my $sum = shift;
       $sum += $_ for @_;

    $sum;
}
