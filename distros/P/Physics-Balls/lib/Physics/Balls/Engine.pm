package Physics::Balls::Engine;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

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

Version 0.01

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
C<segments> and, when C<< $shot->{trace} >> is set, C<energy>.

=head2 DESTROY

Frees the world.

=cut
