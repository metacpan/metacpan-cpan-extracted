use 5.010001;
use strict;
use warnings;

package Story::Interact::Harness;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001010';

use Story::Interact::State ();

use Moo::Role;
use Types::Common -types;
use URI::Query ();
use namespace::clean;

use constant DEBUG       => !!$ENV{PERL_STORY_INTERACT_DEBUG};
use constant FIRST_PAGE  => $ENV{PERL_STORY_INTERACT_START} // 'main';

has 'state' => (
	is        => 'ro',
	isa       => Object,
	builder   => sub { Story::Interact::State->new },
);

has 'page_source' => (
	is        => 'ro',
	isa       => Object,
	required  => 1,
);

sub get_page {
	my ( $self, $page_id ) = @_;
	
	my $state = $self->state;
	if ( $page_id =~ /\A(.+)\?(.+)\z/ms ) {
		$page_id = $1;
		my $params = URI::Query->new( $2 )->hash;
		$state->params( $params );
	}
	else {
		$state->params( {} );
	}
	
	return $self->page_source->get_page( $state, $page_id );
}

1;
