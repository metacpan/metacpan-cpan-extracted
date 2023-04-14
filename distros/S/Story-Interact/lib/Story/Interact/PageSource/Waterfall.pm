use 5.010001;
use strict;
use warnings;

package Story::Interact::PageSource::Waterfall;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001010';

use Moo;
use Types::Common -types;
use Types::Path::Tiny -types;
use List::Util qw( uniqstr );
use namespace::clean;

with 'Story::Interact::PageSource';

has 'sources' => (
	is        => 'ro',
	isa       => ArrayRef->of( ConsumerOf->of( 'Story::Interact::PageSource' ) ),
	required  => 1,
);

sub get_source_code {
	my ( $self, $page_id ) = @_;
	for my $source ( @{ $self->sources } ) {
		my $code = $source->get_source_code( $page_id );
		return $code if defined $code;
	}
	return;
}

sub all_page_ids {
	my ( $self ) = @_;
	return uniqstr( map $_->all_page_ids, @{ $self->sources } );
}

1;
