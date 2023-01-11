use 5.010001;
use strict;
use warnings;

package Story::Interact::PageSource;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use Story::Interact::Page ();
use Story::Interact::Syntax ();

use Moo::Role;
use Types::Common -types;
use Carp qw( croak );
use Safe ();
use namespace::clean;

requires 'get_source_code';

has 'safe' => (
	is        => 'ro',
	isa       => Object,
	builder   => 1,
);

sub _build_safe {
	my $compartment = Safe->new;
	$compartment->permit(
		qw/ :base_core :base_mem :base_loop :base_math sprintf qr /
	);
	$compartment->share_from(
		'Story::Interact::Syntax',
		\@Story::Interact::Syntax::EXPORT,
	);
	return $compartment;
}

sub get_page {
	my ( $self, $state, $page_id ) = @_;
	my $code = $self->get_source_code( $page_id );

	return Story::Interact::Page->new( id => ':end' ) unless $code;

	Story::Interact::Syntax::START( $state, $page_id );
	$self->safe->reval( "$code; 1", 1 )
		or croak( "Died on page '$page_id': $@" );
	return Story::Interact::Syntax::FINISH( $state );
}

1;
