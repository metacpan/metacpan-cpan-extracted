#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Every engine refusal is a flag on the outcome or an undef return with the
# name in error, never an exception: a caller that gets one has a turn to
# record or a body to place, not a stack to unwind. Argument errors, which
# are the caller's bug, do die, and those are named here too so the line is
# clear.

use Physics::Terrain;

plan tests => 16;

my $flat = { profile => 'flat', floor => 400 };

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0);
	my $out = $field->run_turn(0, [], { tick => 0, weapon => 9, angle => 512, power => 50 });
	is $out->{error}, 'weapon', 'a shot naming no weapon is the weapon error';
	is $field->error, 'weapon', 'and the field says so';
	ok((grep { $_->[1] eq 'error' } @{ $out->{events} }), 'with an error event');
	is $field->phase, 'done', 'and the turn is over';
	is $out->{shot}, undef, 'nothing was fired';
}

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0);
	is $field->start_turn(5), undef, 'a turn for a body that does not exist is refused';
	is $field->advance(0), 'idle', 'and nothing advances';
	is $field->error, undef, 'with no error left behind on the field';
}

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, place => 'none');
	my $n = 0;
	$n++ while defined $field->add_body($n % 4, 100 + $n * 30, 400);
	is $n, 32, '32 bodies stand, the 33rd is refused';
	is $field->error, 'bodies', 'as the bodies error';
	is $field->body_count, 32, 'and the count did not move';
}

{
	my $field = Physics::Terrain->new(seed => 1, gen => $flat, bodies => [[0, 300, 0]], wind => 0);
	my $other = Physics::Terrain->new(seed => 1, gen => { profile => 'flat', W => 640, H => 320, floor => 200 }, place => 'none');
	my $snap = $other->snapshot;
	ok !eval { $field->restore($snap); 1 }, 'restoring a snapshot of another size dies';
	like $@, qr/another size/, 'and says so';
	ok !eval { Physics::Terrain->new(seed => 1, teams => 5); 1 }, 'five teams die';
	ok !eval { Physics::Terrain->new(seed => 1, bodies => [[7, 100, 0]]); 1 }, 'seat 7 dies';
	ok !eval { Physics::Terrain->new(seed => 1, sculpt => [['bevel', 1, 2, 3, 4]]); 1 }, 'an unknown sculpt op dies';
}
