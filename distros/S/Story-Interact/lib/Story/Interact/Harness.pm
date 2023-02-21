use 5.010001;
use strict;
use warnings;

package Story::Interact::Harness;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001009';

use Story::Interact::State ();

use Moo::Role;
use Types::Common -types;
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
	return $self->page_source->get_page( $self->state, $page_id );
}

1;
