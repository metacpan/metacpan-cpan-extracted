package Physics::Balls::Engine;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.07';

use Physics::Balls;

sub new {
	my ($class, %desc) = @_;
	my $ptr = _new_world(\%desc);
	return bless { ptr => $ptr }, $class;
}

sub strike {
	my ($self, $layout, $shot) = @_;
	return _strike($self->{ptr}, $layout, $shot);
}

sub strike_v1 {
	my ($self, $layout, $shot) = @_;
	return _strike_v1($self->{ptr}, $layout, $shot);
}

sub advance {
	my ($self, $layout, $tick) = @_;
	return _advance($self->{ptr}, $layout, $tick);
}

sub bad_size_refused {
	my ($self) = @_;
	return _bad_size_refused($self->{ptr});
}

sub DESTROY {
	my ($self) = @_;
	_free_world(delete $self->{ptr}) if $self->{ptr};
	return;
}

1;

__END__

=encoding utf8

=head1 NAME

Physics::Balls::Engine - the door to the C engine

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    my $engine = Physics::Balls::Engine->new(%description);
    my $raw = $engine->strike(\@layout, { ball => 0, dx => 1_000_000, dy => 0, power => 500, sx => 0, sy => 0 });

=head1 DESCRIPTION

Owns one world and frees it when it goes away. L<Physics::Balls::World> builds
one of these lazily and L<Physics::Balls::Strike> calls it; nothing else needs
to. The description and the answer are the plain hashes and arrays the outcome
classes wrap, in the shape the prototype's fixtures use.

=head1 METHODS

=head2 new

    my $engine = Physics::Balls::Engine->new(L => ..., W => ..., R => ..., walls => [...], noses => [...], gates => [...], mu => {...}, e => {...}, vmax => 8, g => 9.81);

=head2 strike

    my $raw = $engine->strike(\@layout, \%shot);

Returns a hash with C<t>, C<n>, C<error>, C<events>, C<rest>, C<holed>,
C<segments> and, when C<< $shot->{trace} >> is set, C<energy>. Goes through
the ABI 2 entry point, so a row may carry a kind and a shot an adjust.

=head2 strike_v1

The same shot through the ABI 1 entry point, rows of three and no adjust.
The v1 functions are wrappers over the v2 path with the v1 defaults, and
this is how a test proves that they give the same doubles.

=head2 advance

    my $raw = $engine->advance(\@rows, { t => 20000 });

Since 0.07, the ABI 4 entry point: rows of C<[id, x, y, kind, vx, vy]>
advanced C<t> microseconds. The hash is the strike's plus C<state>,
C<[[id, x, y, vx, vy, mode], ...]> at the horizon. L<Physics::Balls::Tick>
validates and wraps it; a hot loop may call this directly.

=head2 bad_size_refused

True when the engine refuses a v2 description and a v2 shot whose C<size> is
smaller than this version needs. A probe for a test.

=head2 DESTROY

Frees the world.

=cut
