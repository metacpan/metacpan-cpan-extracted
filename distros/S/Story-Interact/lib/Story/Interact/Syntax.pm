use 5.010001;
use strict;
use warnings;

package Story::Interact::Syntax;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001003';

use Story::Interact::Page ();

use Exporter::Shiny;

our @EXPORT = qw(
	text
	next_page
	at
	world
	location
	player
	npc
	define_npc
	visited
	true
	false
	INTERNAL_STATE
);

my ( $page, $state );

sub START {
	( $state, my $page_id ) = @_;
	$page = Story::Interact::Page->new( id => $page_id );
}

sub text {
	$page->add_text( @_ );
}

sub next_page {
	$page->add_next_page( @_ );
}

sub at {
	if ( @_ ) {
		my ( $code ) = @_;
		$page->_set_location( $code );
	}
	return $page->location;
}

sub world () {
	return $state->world;
}

sub location {
	my ( $code ) = @_ ? @_ : ( at() );
	$state->location->{$code} //= {};
}

sub player () {
	return $state->player;
}

sub npc ($) {
	my ( $code ) = @_;
	return $state->character->{$code};
}

sub define_npc {
	my ( $code, %attrs ) = @_;
	return $state->define_npc( $code, %attrs );
}

sub visited {
	my ( $code ) = @_ ? @_ : ( $page->id );
	$state->visited->{$code} //= 0;
}

sub FINISH {
	$state->update_from_page( $page );
	my $return = $page;
	undef $page;
	return $return;
}

sub pp {
	require JSON::PP;
	print JSON::PP
		->new
		->pretty( 1 )
		->canonical( 1 )
		->convert_blessed( 1 )
		->encode( shift ), "\n";
}

sub DEBUG {
	eval( shift() . ";" );
}

sub true () {
	!!1;
}

sub false () {
	!!0;
}

sub INTERNAL_STATE () {
	return $state;
}

1;
