=head1 NAME

Pangloss::Search - search through Pangloss Terms.

=head1 SYNOPSIS

  use Pangloss::Search;
  my $search = new Pangloss::Search;

  $search->terms( $terms->clone )
         ->categories( $categories )
         ->concepts( $concepts )
         ->languages( $languages )
         ->users( $users );

  $search->add_filters( @filters );

  $search->apply;

  $results = $search->results;

=cut

package Pangloss::Search;

use Error qw( :try );
use UNIVERSAL qw( isa );

use Pangloss::Terms;
use Pangloss::Users;
use Pangloss::Concepts;
use Pangloss::Languages;
use Pangloss::Categories;
use Pangloss::Search::Results;

use base      qw( Pangloss::Object );
use accessors qw( filters  categories  concepts
		  languages terms users results );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];

sub init {
    my $self = shift;
    $self->filters( [] )
         ->categories( Pangloss::Categories->new )
         ->concepts( Pangloss::Concepts->new )
         ->languages( Pangloss::Languages->new )
         ->terms( Pangloss::Terms->new )
         ->users( Pangloss::Users->new );
}

sub add_filters {
    my $self = shift;
    $self->add_filter($_) for (@_);
    return $self;
}

sub add_filter {
    my $self   = shift;
    my $filter = shift;
    return unless isa( $filter, 'Pangloss::Search::Filter' );
    push @{ $self->filters }, $filter;
    return $self;
}

sub apply {
    my $self = shift;
    my $mode = shift || 'intersect';

    my $apply_method = "apply_$mode";
    unless ($self->can( $apply_method )) {
	$self->emit( "don't know how to apply $mode" );
	return;
    }

    $self->results( Pangloss::Search::Results->new->parent($self) )
         ->$apply_method
	 ->results->parent(undef);

    return $self;
}

sub apply_intersect {
    my $self = shift;

  I_TERM:
    foreach my $term ($self->terms->list) {
	my @filters = @{ $self->filters };
	while (my $filter = shift @filters) {
	    $filter->parent( $self );
	    my $applies = $filter->applies_to( $term );
	    $filter->parent( undef );
	    if ($applies) {
		# only add if matches all filters
		$self->remove_term( $term )
		     ->add_result( $term )
		       unless (scalar @filters);
	    } else {
		next I_TERM;
	    }
	}
    }

    return $self;
}

sub apply_union {
    my $self = shift;

    $self->results( Pangloss::Search::Results->new );

  U_TERM:
    foreach my $term ($self->terms->list) {
	foreach my $filter (@{ $self->filters }) {
	    $filter->parent( $self );
	    my $applies = $filter->applies_to( $term );
	    $filter->parent( undef );
	    if ($applies) {
		$self->remove_term( $term )
		     ->add_result( $term );
		next TERM;
	    }
	}
    }

    return $self;
}

sub add_result {
    my $self = shift;
    my $term = shift;

    $self->results->add( $term->clone );

    return $self;
}

sub remove_term {
    my $self = shift;
    my $term = shift;

    try {
	$self->terms->remove( $term );
    } catch Error with {
	$self->emit( "WARNING: error removing $term: " . shift );
    };

    return $self;
}


1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Search through a collection of L<Pangloss::Terms>.

=head1 METHODS

TODO: document other API methods.

B<Note:> the $obj->terms collection gets modified, so you should consider
cloning it before handing it over...  individual terms that end up in the
result set are cloned, so you don't have to worry about doing a deep_clone().

=over 4

=item $obj = $obj->apply( [ $mode ] )

Applies the filters to the L<Pangloss::Terms>, and returns this object.  Results
are accessible via $obj->results() (a L<Pangloss::Search::Results> object).

The results will contain all terms that match the filters (ie: those where
$filter->applies_to( $term ) evaluates to C<true>).

The $mode argument is a set-theory switch that affects how terms will be
added to the result set.  It defaults to 'intersect', but may also be set to
'union'.

Note that collection of terms will be modified - this means you should give a
shallow copy of the terms to search objects.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>,
L<Pangloss::Search::Request>,
L<Pangloss::Search::Results>,
L<Pangloss::Search::Filters>,

=cut

