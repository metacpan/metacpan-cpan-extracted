use strict;
use warnings;
use Test::More tests => 8;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::Zed') };

my $zed = Statistics::Zed->new(ccorr => 1, tails => 2,);

my %ref = (
	z_value => 1.625,
	p_value => 0.10416,
);

my %res = ();

# supports given params, unreferenced:
eval { ($res{'z_value'}, $res{'p_value'}) = $zed->score(
	observed => 12,
    expected => 5,
    variance => 16,
);};
ok(!$@, $@);

foreach (qw/z_value p_value/) {
    ok(defined $res{$_} );
    ok(equal($res{$_}, $ref{$_}), "$_  $res{$_} != $ref{$_}");
}

# supports unnamed arg to z2p:
$res{'p_value'} = $zed->z2p($ref{'z_value'});
ok(equal($res{'p_value'}, $ref{'p_value'}), "p_value  $res{'p_value'} != $ref{'p_value'}");

# supports named arg to z2p:
$res{'p_value'} = $zed->z2p(value => $ref{'z_value'});
ok(equal($res{'p_value'}, $ref{'p_value'}), "p_value  $res{'p_value'} != $ref{'p_value'}");

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;