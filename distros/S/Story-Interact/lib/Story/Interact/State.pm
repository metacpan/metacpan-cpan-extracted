use 5.010001;
use strict;
use warnings;

package Story::Interact::State;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use Story::Interact::Character ();

use Moo;
use Types::Common -types;
use namespace::clean;

has 'world' => (
	is        => 'ro',
	isa       => HashRef,
	builder   => sub { {} },
);

has 'character' => (
	is        => 'ro',
	isa       => HashRef->of( Object ),
	builder   => sub { {} },
);

has 'location' => (
	is        => 'ro',
	isa       => HashRef->of( HashRef ),
	builder   => sub { {} },
);

has 'visited' => (
	is        => 'ro',
	isa       => HashRef->of( PositiveOrZeroInt ),
	builder   => sub { {} },
);

sub BUILD {
	my ( $self, $arg ) = @_;
	$self->character->{player} = Story::Interact::Character->new( name => 'Anon' );
}

sub player {
	my ( $self ) = @_;
	return $self->character->{player};
}

sub update_from_page {
	my ( $self, $page ) = @_;
	++$self->visited->{ $page->id };
	$self->player->_set_location( $page->location );
	return $self;
}

1;
