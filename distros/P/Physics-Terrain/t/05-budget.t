#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The caps are errors, not silent stops. A turn that has not settled within
# settle_cap ticks of its shot ends with the tick cap error and an error
# event; a turn with no shot expires at live_cap with an expire event and no
# error, because that is a rule of the game rather than a failure; and the
# body cap is a refusal, not a truncation.

use Physics::Terrain;

plan tests => 10;

my $flat = { profile => 'flat', floor => 400 };

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0, settle_cap => 20);
	my $out = $field->run_turn(0, [], { tick => 0, weapon => 1, angle => 512, power => 50 });
	is $out->{error}, 'tick cap', 'a grenade needs 180 ticks; a settle cap of 20 is the tick cap error';
	is $out->{ticks}, 21, 'reported on the tick after the cap';
	is $out->{settledAt}, -1, 'and the turn never settled';
	ok((grep { $_->[1] eq 'error' } @{ $out->{events} }), 'with an error event');
}

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0, live_cap => 30);
	my $out = $field->run_turn(0, [[0, Physics::Terrain::RIGHT()]], undef);
	is $out->{error}, undef, 'a turn with no shot is not an error';
	ok((grep { $_->[1] eq 'expire' } @{ $out->{events} }), 'it expires');
	is $out->{shot}, undef, 'without a shot';
	is $out->{ticks}, 31, 'after the live cap and one settling tick';
}

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0);
	my $out = $field->run_turn(0, [], { tick => 0, weapon => 1, angle => 512, power => 50 });
	is $out->{error}, undef, 'the same grenade under the default cap settles';
	cmp_ok $out->{settledAt}, '>=', 180, 'after its fuse';
}
