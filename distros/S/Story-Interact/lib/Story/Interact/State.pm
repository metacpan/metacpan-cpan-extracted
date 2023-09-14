use 5.010001;
use strict;
use warnings;

package Story::Interact::State;

warn "LOADED DEV VERSION!";

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001014';

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

sub _maybe_encrypt {
	my ( $self, $data ) = @_;
	my $key = $ENV{PERL_STORY_INTERACT_KEY} or return $data;
	
	require Crypt::Mode::OFB;
	require Bytes::Random::Secure;
	my $iv = Bytes::Random::Secure::random_string_from( 'abcdefghijklmnopqrstuvwxyz0123456789', 8 );
	my $m = Crypt::Mode::OFB->new( 'CAST5' );
	return sprintf( 'CRYPTX:%s:%s', $iv, $m->encrypt( $data, $key, $iv ) );
}

sub _maybe_decrypt {
	my ( $class, $data ) = @_;
	
	if ( substr( $data, 0, 7 ) eq 'CRYPTX:' ) {
		my $key = $ENV{PERL_STORY_INTERACT_KEY} or die 'PERL_STORY_INTERACT_KEY not found!';
		require Crypt::Mode::OFB;
		my $m = Crypt::Mode::OFB->new( 'CAST5' );
		my $iv = substr( $data, 7, 8 );
		my $ciphertext = substr( $data, 16 );
		return $m->decrypt( $ciphertext, $key, $iv );
	}
	
	die 'Failed to load non-encrypted state!!!' if $ENV{PERL_STORY_INTERACT_FORCE_ENCRYPTED};
	return $data;
}

sub dump {
	my ( $self ) = @_;
	require Storable;
	require MIME::Base64;
	require Compress::Bzip2;
	my $frozen = Compress::Bzip2::memBzip( Storable::nfreeze( $self ) );
	my $encrypted = $self->_maybe_encrypt( $frozen );
	return MIME::Base64::encode_base64( $encrypted );
}

sub load {
	my ( $class, $data ) = @_;
	require Storable;
	require MIME::Base64;
	require Compress::Bzip2;
	my $frozen = MIME::Base64::decode_base64( $data );
	my $decrypted = $class->_maybe_decrypt( $frozen );
	if ( my $unzipped = Compress::Bzip2::memBunzip( $decrypted ) ) {
		return Storable::thaw( $unzipped );
	}
	return Storable::thaw( $decrypted );
}

1;
