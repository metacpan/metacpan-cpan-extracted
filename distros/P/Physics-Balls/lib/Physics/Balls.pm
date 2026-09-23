package Physics::Balls;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Physics::Balls', $VERSION);

use Physics::Balls::Engine;
use Physics::Balls::Error;
use Physics::Balls::Ball;
use Physics::Balls::Table;
use Physics::Balls::World;
use Physics::Balls::Strike;
use Physics::Balls::Tick;
use Physics::Balls::Outcome;

sub strike {
	my ($class, $world, %args) = @_;
	my $layout = delete $args{layout};
	my $strike = Physics::Balls::Strike->new(%args);
	return $strike->play($world, $layout);
}

sub advance {
	my ($class, $world, %args) = @_;
	my $layout = delete $args{layout};
	my $tick = Physics::Balls::Tick->new(%args);
	return $tick->play($world, $layout);
}

sub abi_version { return Physics::Balls::Engine::_abi_version() }

sub float_eval_method { return Physics::Balls::Engine::_float_eval_method() }

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls - balls on a table with friction, walls and pockets

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use Physics::Balls;

    my $table = Physics::Balls::Table->new(
        L => 2.540, W => 1.270, R => 0.028575,
        corner => { mouth => 0.1175, jaw_deg => 142, shelf => 0.041 },
        side   => { mouth => 0.1302, jaw_deg => 104, shelf => 0.008 },
    );
    my $world = Physics::Balls::World->from_table($table,
        mu => { s => 0.2, r => 0.02, sp => 0.044 },
        e  => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 },
        vmax => 8, g => 9.81,
    );

    my $out = Physics::Balls->strike($world,
        layout => [ [0, 63500, 63500], [1, 190500, 63500] ],
        ball => 0, dx => 1_000_000, dy => 0, power => 520, sx => 0, sy => 0,
    );
    if ($out->error) { die $out->message }
    print $out->t, " seconds, ", scalar @{ $out->events }, " events\n";
    my $payload = $out->to_payload;    # what a game stores and a client plays back

=head1 DESCRIPTION

An engine for round balls of one size on a flat surface: sliding and rolling
friction, side spin, walls a ball bounces off, nose points it can rattle
against, and gates it drops through. It knows nothing about any game. A pool
or snooker adapter describes its table, sends a strike, and reads the outcome:
the contacts in order, where every ball came to rest, which balls dropped and
where, and the trajectory as segments a client can play back without
simulating anything itself.

The simulation is event-based and analytic. A sliding ball is a parabola under
constant deceleration, a rolling ball a straight line, and every contact time
is the first downward zero of a polynomial found by a fixed number of
bisections in a fixed order. The same inputs give the same outcome, bit for
bit, on every platform that keeps IEEE doubles honest, which is why the inputs
are integers, the build refuses fused multiply-adds, and a 32-bit x86 build
asks for the SSE unit rather than the x87 one.

Since 0.03 a ball may curve. A world declares kinds of ball, a layout row
names its kind, and a ball whose kind has a curve runs as a chain of short
parabolas that bends, turned at each step by a rotation of its velocity and
its roll together with no trigonometry, so every segment is still a segment
and the turn adds no energy. A shot may also carry an adjust, a change in the
surface under the struck ball once it crosses a line. The curve's turn rate
is a house law with fitted constants and not a model of ice or of a green;
L<Physics::Balls::World> says so where the constants are. A world that
declares no kinds behaves exactly as before, bit for bit.

Since 0.04 a kind may also give a body its own radius, mass and friction, a
wider reach against its own kind, and a speed above which it is down and
leaves play when it stops: a bowling ball among ten pins. A shot may carry a
release roll off its line, which is how that ball hooks. Every one of these
enters the arithmetic as a factor that is exactly one when a world declares
none of it, so a table's fixtures are the same doubles they were.

Since 0.07 the world can be advanced a fixed time from a layout whose rows
carry a velocity, for a game that ticks rather than shoots: an air hockey
puck between two mallets that a player drives. A strike is the same
instructions it was.

It is the engine behind the pool, snooker, nine-ball and minigolf at
L<https://peer2peergames.com>.

=head2 Units

A description is in metres, seconds and metres per second. A layout and a rest
position are integers in hundredths of a millimetre. A shot is integers: a
direction C<dx, dy> in plus or minus 1,000,000, C<power> 0 to 1000, a tip
offset C<sx, sy> in thousandths of the radius from -500 to 500, and a release
roll C<tx, ty> in plus or minus 1,000,000 with C<spin> 0 to 1000. Segments
are doubles in metres and seconds.

=head1 METHODS

=head2 strike

    my $out = Physics::Balls->strike($world, layout => \@layout, %shot);

Builds a L<Physics::Balls::Strike> from C<%shot>, validates it against the
layout, and plays it on the world. Returns a L<Physics::Balls::Outcome>, or a
L<Physics::Balls::Error> when the shot or the layout is refused; both answer
C<error>, so C<< $out->error >> is the one test a caller needs.

=head2 advance

    my $out = Physics::Balls->advance($world, layout => \@rows, t => 20000);

Since 0.07. Every row is C<[id, x, y, kind, vx, vy]>, the velocity in
hundredths of a millimetre a second, and the world is advanced exactly C<t>
microseconds: the call a live game makes fifty times a second, setting the
bodies it drives to a velocity of its own each tick and reading every body
back from the outcome's C<state>. Builds a L<Physics::Balls::Tick>, validates
it, and returns a L<Physics::Balls::Outcome> or the L<Physics::Balls::Error>
that refused it.

=head2 abi_version

The version of the C table in C<pb_abi.h>: 4 since 0.07. A consumer requires
at least the version it was written against, never exactly it.

=head2 float_eval_method

How the compiler that built the engine evaluates a double between operations,
as its C<float.h> reports: 0 when every operation rounds to a double, which is
what the same-doubles promise needs and what the build asks a 32-bit x86
compiler for; 2 when a build was left on the x87 unit, which holds 80 bits
between operations and lands a few ulps from the recorded fixtures; negative
when the header does not say. The tests that compare against recorded doubles
skip on anything but 0 and give this as the reason.

=head1 THE C INTERFACE

C<include/pb_abi.h> is installed with the module and describes a versioned
function-pointer table, resolved at runtime through
C<Physics::Balls::Engine::_abi_ptr>, so another module can roll balls with no
Perl frame in between. The engine itself is perl-free and the same C compiles
alone. ABI 2 appends C<world_new_ex> and C<strike_ex>, which take
size-prefixed structs that grow by append; the ABI 1 structs and entry points
are frozen and are wrappers over the same path with the ABI 1 defaults. ABI 3
appends members to the kind, the shot and the outcome and no function. ABI 4
appends C<advance>, which takes rows that may carry a velocity and a horizon,
and appends the state at the horizon to the outcome.

=head1 SEE ALSO

L<Physics::Balls::World>, L<Physics::Balls::Table>, L<Physics::Balls::Strike>,
L<Physics::Balls::Outcome>, L<Physics::Balls::Error>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
