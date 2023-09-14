use 5.010001;
use strict;
use warnings;

package Story::Interact::Harness::Test;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001014';

use Moo;
use Types::Common -types;
use namespace::clean;

with 'Story::Interact::Harness';

has page => (
	is        => 'rwp',
	isa       => Object,
);

sub BUILD {
	my ( $self, $args ) = @_;
	my $page = $self->get_page( 'main' ); # hard code for testing
	$self->_set_page( $page );
}

sub page_text {
	my ( $self ) = @_;
	join qq{\n\n}, @{ $self->page->text };
}

sub page_location {
	my ( $self ) = @_;
	$self->page->location;
}

sub has_next_page {
	my ( $self, $regexp ) = @_;
	for my $next_page ( @{ $self->page->next_pages } ) {
		return $next_page if $next_page->[1] =~ $regexp;
	}
	return 0;
}

sub go {
	my ( $self, $regexp ) = @_;
	my $next_page = $self->has_next_page( $regexp ) or return 0;
	my $page = $self->get_page( $next_page->[0] );
	$self->_set_page( $page );
	return 1;
}

1;
