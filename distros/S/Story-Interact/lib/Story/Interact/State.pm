use 5.010001;
use strict;
use warnings;

package Story::Interact::State;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001005';

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
	$self->define_npc( player => ( name => 'Anon' ) );
}

sub player {
	my ( $self ) = @_;
	return $self->character->{player};
}

sub define_npc {
	my ( $self, $code, %attrs ) = @_;
	return if defined $self->character->{$code};
	$self->character->{$code} = Story::Interact::Character->new( %attrs );
}

sub update_from_page {
	my ( $self, $page ) = @_;
	++$self->visited->{ $page->id };
	$self->player->_set_location( $page->location );
	return $self;
}

sub dump {
	my ( $self ) = @_;
	require Storable;
	require MIME::Base64;
	return MIME::Base64::encode_base64( Storable::nfreeze( $self ) );
}

sub load {
	my ( $class, $data ) = @_;
	require Storable;
	require MIME::Base64;
	return Storable::thaw( MIME::Base64::decode_base64( $data ) );
}

1;
