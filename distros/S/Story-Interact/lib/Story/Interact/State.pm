use 5.010001;
use strict;
use warnings;

package Story::Interact::State;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001012';

use Story::Interact::Character ();

use Moo;
use Module::Runtime qw( use_package_optimistically );
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

has 'character_class' => (
	is        => 'ro',
	isa       => Str,
	builder   => sub { 'Story::Interact::Character' },
);

has 'params' => (
	is        => 'rw',
	isa       => HashRef,
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
	
	my $character_class = delete( $attrs{class} ) // $self->character_class;
	$self->character->{$code} = use_package_optimistically( $character_class )->new( %attrs );
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
	require Compress::Bzip2;
	my $frozen = Compress::Bzip2::memBzip( Storable::nfreeze( $self ) );
	return MIME::Base64::encode_base64( $frozen );
}

sub load {
	my ( $class, $data ) = @_;
	require Storable;
	require MIME::Base64;
	require Compress::Bzip2;
	my $frozen = MIME::Base64::decode_base64( $data );
	if ( my $unzipped = Compress::Bzip2::memBunzip($frozen) ) {
		return Storable::thaw( $unzipped );
	}
	return Storable::thaw( $frozen );
}

1;
