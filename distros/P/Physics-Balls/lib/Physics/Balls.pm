package Physics::Balls;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Physics::Balls', $VERSION);

use Physics::Balls::Engine;
use Physics::Balls::Error;
use Physics::Balls::Ball;
use Physics::Balls::Table;
use Physics::Balls::World;
use Physics::Balls::Strike;
use Physics::Balls::Outcome;

sub strike {
	my ($class, $world, %args) = @_;
	my $layout = delete $args{layout};
	my $strike = Physics::Balls::Strike->new(%args);
	return $strike->play($world, $layout);
}

sub abi_version { return Physics::Balls::Engine::_abi_version() }

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls - balls on a table with friction, walls and pockets

=head1 VERSION

Version 0.02

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
are integers and the build refuses fused multiply-adds.

It is the engine behind the pool, snooker, nine-ball and minigolf at
L<https://peer2peergames.com>.

=head2 Units

A description is in metres, seconds and metres per second. A layout and a rest
position are integers in hundredths of a millimetre. A shot is integers: a
direction C<dx, dy> in plus or minus 1,000,000, C<power> 0 to 1000, and a tip
offset C<sx, sy> in thousandths of the radius from -500 to 500. Segments are
doubles in metres and seconds.

=head1 METHODS

=head2 strike

    my $out = Physics::Balls->strike($world, layout => \@layout, %shot);

Builds a L<Physics::Balls::Strike> from C<%shot>, validates it against the
layout, and plays it on the world. Returns a L<Physics::Balls::Outcome>, or a
L<Physics::Balls::Error> when the shot or the layout is refused; both answer
C<error>, so C<< $out->error >> is the one test a caller needs.

=head2 abi_version

The version of the C table in C<pb_abi.h>.

=head1 THE C INTERFACE

C<include/pb_abi.h> is installed with the module and describes a versioned
function-pointer table, resolved at runtime through
C<Physics::Balls::Engine::_abi_ptr>, so another module can roll balls with no
Perl frame in between. The engine itself is perl-free and the same C compiles
alone.

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
