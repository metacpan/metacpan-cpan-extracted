package Physics::Terrain;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Physics::Terrain', $VERSION);

use Physics::Terrain::Snapshot;

1;

__END__

=encoding utf8

=head1 NAME

Physics::Terrain - a destructible field, bodies that walk and fall on it, shells that carve it

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Physics::Terrain;

    my $field = Physics::Terrain->new(seed => 7, teams => 2);

    my $out = $field->run_turn(0,
        [ [0, Physics::Terrain::RIGHT], [60, 0] ],
        { tick => 90, weapon => 0, angle => 512, power => 70 });

    say $out->{events}[0][1];      # 'fire'
    say $out->{end}{health}[4];    # what the shell left of Blue's first

    # a tick at a time, for a live player or a bot
    $field->start_turn(1);
    my $phase = $field->advance(Physics::Terrain::LEFT);
    $phase = $field->advance(0, { weapon => 1, angle => 1536, power => 40 });
    $phase = $field->advance(0) while $phase ne 'done';
    my $same = $field->outcome;

=head1 DESCRIPTION

A field of cells generated from a seed, with a ground, overhangs and caves;
bodies of one size that stand on it, walk up and down three cells at a time,
jump and fall; projectiles that fly under gravity and wind, bounce, split in
the air or burst on contact or on a fuse; and explosions that carve a disc out
of the ground, hurt everything in reach and throw it. A chunk cut free floats.
The engine knows nothing about a game beyond a seat number on each body: it
places a squad per seat, plays one turn from an input log, and reports what
happened.

Everything is an integer, and the same inputs give the same integers on every
platform. Positions and velocities are at 1/256 of a cell; a tick is 1/60 s;
an angle is 0 to 4095 with 0 to the right and 1024 straight up; a power is 1
to 100; wind is -20 to 20. A turn is live for up to 1800 ticks of input and
then settles for up to 1800 more, and running past that is reported as an
error, never as a silent stop.

The recorded turns and the mask digests under F<t/fixtures> come from the
JavaScript prototype the engine was transliterated from, and the engine
reproduces them bit for bit, which is what lets a browser simulate a turn
live and a server replay the same input log to the same result.

=head1 CONSTANTS

The held-key bits an input log carries, and the modes a body reports.

=over

=item LEFT

1, walking left.

=item RIGHT

2, walking right.

=item JUMP

4, held once per jump.

=item STANDING

Mode 0.

=item WALKING

Mode 1.

=item FALLING

Mode 2.

=item FLYING

Mode 3: jumping, or thrown by a blast.

=back

=head1 CLASS METHODS

=head2 new

    my $field = Physics::Terrain->new(%options);
    my $field = Physics::Terrain->new(\%options);

Builds a field and places the bodies. The options:

=over

=item seed

An unsigned 32-bit integer. The field, the landing spots and every turn's
wind follow from it. Default 1.

=item teams, per_team

How many seats and how many bodies each, 1 to 4 and 1 to 8, at most 32 bodies
in all. Default two teams of four. Seat C<t>'s bodies are indices C<t x
per_team> onward, in placement order.

=item place

C<teams> (the default) places every team on generated landing spots;
C<explicit> places the C<bodies> given; C<none> places nobody.

=item bodies

For C<explicit>: C<[[seat, x, y_from, hp], ...]>. Each body is dropped onto
the first ground at or below C<y_from> in column C<x>; C<hp> is optional
and defaults to 100. Giving C<bodies> implies C<explicit>.

=item gen

A hash of generator settings. C<profile> is C<noise> (the default), C<flat>
(solid from row C<floor> down) or C<empty>. C<W> and C<H> size the field,
default 1280 by 640. The noise settings C<coarse>, C<fine>, C<cave>,
C<threshold>, C<biasScale>, C<biasOffset>, C<caveLo>, C<caveHi>, C<caveTop>,
C<caveBottom>, C<platform> and C<headroom> take the prototype's defaults when
absent.

=item sculpt

Ops applied after generation, in order: C<['fill', x0, y0, x1, y1]>,
C<['clear', x0, y0, x1, y1]>, C<['slope', x0, y0, x1, y1]> (every cell on or
below the segment), C<['disc', x, y, r]> and C<['platform', x, ground_row,
half_width, headroom]>.

=item wind

Fixes every turn's wind; otherwise each turn draws one from the seed.

=item live_cap, settle_cap

How many ticks of input a turn takes before it expires, and how many ticks
it may take to settle after the shot before that is reported as the
C<tick cap> error. Default 1800 each.

=back

=head2 launch

    my ($vx, $vy) = Physics::Terrain->launch($weapon, $angle, $power);

The velocity a weapon leaves the muzzle with, in units a tick, without
firing.

=head2 weapons

    my $list = Physics::Terrain->weapons;

The five weapons as hashes: C<id>, C<name>, C<kind>, C<speedMax>, C<wind>,
C<fuse>, C<radius>, C<damage>, C<knock>, and where they apply C<bounce>,
C<friction>, C<range>, C<count>, C<spread> and C<pop>. A shot names a weapon
by its index here: 0 the bazooka, 1 the grenade, 2 the shotgun, 3 the
cluster, 4 the dynamite.

=head2 abi_version

The version of the C table F<include/pt_abi.h> publishes.

=head1 THE FIELD

=head2 width, height, seed, teams, per_team, tick

The field's size in cells, its seed, how it was populated, and the ticks
simulated so far over every turn.

=head2 solid

    my $ground = $field->solid($x, $y);

Whether a cell is ground. Every cell outside the field is air.

=head2 swept

    my ($hit, $x, $y, $px, $py) = $field->swept($x0, $y0, $x1, $y1);

The first solid cell on the segment between two cells, both ends included,
and the last free cell before it. A wall one cell thick is never crossed,
even at a corner.

=head2 carve

    my $cleared = $field->carve($x, $y, $r);

Clears every cell within C<r> of the centre, compared squared, and returns
how many were ground. The ring just outside is marked scorched.

=head2 sculpt

    $field->sculpt([ ['fill', 0, 400, 1279, 639] ]);

Applies sculpt ops, as C<new> does.

=head2 surface_at

    my $row = $field->surface_at($x, $y_from);

The first ground row at or below C<y_from> in a column, or -1.

=head2 count

How many cells are ground.

=head2 mask

    my $digest = Digest::SHA::sha256_hex($field->mask);

The field as packed bytes, row-major, eight cells a byte, the leftmost cell
in the low bit. The fixtures record the SHA-256 of this.

=head2 craters, graves

Every crater carved so far as C<[x, y, r]>, in order, and every body that
died in place as C<[seat, x, y]>.

=head1 THE BODIES

=head2 add_body

    my $index = $field->add_body($seat, $x, $ground_row);

Stands a body on a ground row. Returns undef over the cap of 32, and
C<error> then says C<bodies>.

=head2 body, bodies, body_count

    my $b = $field->body(3);

A body as a hash: C<index>, C<seat>, C<k> (its number within its seat),
C<x>, C<y> (the feet, in units), C<vx>, C<vy>, C<mode>, C<hp>, C<alive>,
C<facing>. C<bodies> is all of them.

=head2 alive

    my $n = $field->alive;        # every seat
    my $n = $field->alive($seat);

How many bodies are alive.

=head1 A TURN

=head2 run_turn

    my $out = $field->run_turn($active, \@inputs, $shot);

Plays a whole turn for one body from a recorded input log and returns the
outcome. C<@inputs> is C<[[tick, bits], ...]>, one entry per change of the
held keys; C<$shot> is C<{tick, weapon, angle, power}> or undef for a turn
that ends without one. The outcome hash carries C<engine>, C<seed>,
C<active>, C<wind>, C<inputs> (the log as recorded, canonical), C<shot>,
C<events> as C<[tick, kind, a, b]> in order (the kinds are C<jump>, C<fire>,
C<ray>, C<hit>, C<explode>, C<bounce>, C<split>, C<lost>, C<hurt>, C<die>,
C<out>, C<land>, C<blast>, C<expire> and C<error>), C<craters> as
C<[x, y, r]> in order, C<trace> with per-body and per-projectile position
lists, C<hashes> (the state hash every 64 ticks), C<end> (the tick, every
body, every body's health and the crater count), C<ticks>, C<settledAt>
and C<error>: undef, or C<tick cap>, C<weapon>, C<projectiles>, C<box>,
C<memory> or C<state>.

=head2 start_turn

    my $wind = $field->start_turn($active);

Begins a turn for a body and returns its wind, or undef for a body that
does not exist.

=head2 advance

    my $phase = $field->advance($bits, $shot);

One tick. C<$bits> is what is held this tick; C<$shot> is given on the one
tick it fires. Returns C<live>, C<settle> or C<done>.

=head2 phase, turn_tick, error

Where the turn is, how many ticks it has run, and the current error name or
undef.

=head2 outcome

The outcome of the turn so far, in the shape C<run_turn> returns.

=head2 hash

    my ($h1, $h2) = $field->hash;

The state hash as two unsigned 32-bit halves, over the tick, the wind, the
craters and every body and projectile.

=head2 snapshot, restore

    my $snap = $field->snapshot;
    $field->restore($snap);

Everything a turn changes, so a turn can be replayed from the same start.
A snapshot is a L<Physics::Terrain::Snapshot> and is only good for the
field it came from.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
