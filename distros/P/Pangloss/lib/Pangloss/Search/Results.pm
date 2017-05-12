=head1 NAME

Pangloss::Search::Results - collection of terms resulting from a search

=head1 SYNOPSIS

  use Pangloss::Search::Results;
  my $results = new Pangloss::Search::Results;

  $results->add( @terms );

  my ($concept) = $results->concepts;
  my $results2  = $results->by_concept( $concept );

  my ($lang)    = $results->languages;
  my $results3  = $results->by_language( $lang );

  my @terms = $results->list;

=cut

package Pangloss::Search::Results;

use strict;
use warnings::register;

use Pangloss::Users;
use Pangloss::Concepts;
use Pangloss::Languages;
use Pangloss::Categories;

use UNIVERSAL qw( isa );
use base      qw( Pangloss::Terms );
use accessors qw( parent concepts languages categories translators proofreaders );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

sub init {
    my $self = shift;
    $self->categories( Pangloss::Categories->new )
         ->languages( Pangloss::Languages->new )
         ->proofreaders( Pangloss::Users->new )
         ->translators( Pangloss::Users->new )
         ->concepts( Pangloss::Concepts->new )
	 ->SUPER::init(@_);
}

sub add {
    my $self = shift;

    foreach my $term (@_) {
	next unless (isa( $term, 'Pangloss::Term' ));
	my $key = $term->key;
	next if ($self->exists( $key ));

	# jump through hoops because we store keys instead of references:
	my $concept = $self->parent->concepts->get( $term->concept );
	my $lang    = $self->parent->languages->get( $term->language );
	#my $xlator  = $self->parent->users->get( $term->creator );
	#my $proofer = $self->parent->users->get( $term->status->creator );
	#my $cat     = $self->parent->categories->get( $concept->category );

	$self->concepts->add( $concept ) unless $self->concepts->exists( $concept );
	$self->languages->add( $lang )   unless $self->languages->exists( $lang );
	#$self->translators->add( $xlator )   unless $self->translators->exists( $xlator );
	#$self->proofreaders->add( $proofer ) unless $self->proofreaders->exists( $proofer );
	#$self->categories->add( $category )  unless $self->categories->exists( $category );

	#$self->{-concepts}->{$term->concept}++;
	#$self->{-languages}->{$term->language}++;
	$self->collection->{$key} = $term;
    }

    return $self;
}

sub by_concept {
    my $self    = shift;
    my $concept = Pangloss::Terms->get_values_key(shift);

    my $results = $self->class->new->parent($self);
    foreach my $key ($self->keys) {
	$results->add( $self->get( $key ) )
	  if (Pangloss::Term->get_concept_from_key( $key ) eq $concept);
    }

    return $results;
}

sub by_language {
    my $self     = shift;
    my $language = Pangloss::Languages->get_values_key(shift);

    my $results = $self->class->new->parent($self);
    foreach my $key ($self->keys) {
	$results->add( $self->get( $key ) )
	  if (Pangloss::Term->get_language_from_key( $key ) eq $language);
    }

    return $results;
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

A collection of L<Panglos::Term>s indexed by concept and language.
Inherits from L<Pangloss::Terms>.

=head1 METHODS

TODO: document API methods.

=over 4

=back

=head1 NOTES

Ordering by I<category>, I<translator>, and I<proofreader> should be fairly
easy to add in the future.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Search>,
L<Pangloss::Search::Results::Pager>

L<Pangloss::Terms>,
L<Pangloss::Users>,
L<Pangloss::Concepts>,
L<Pangloss::Languages>,
L<Pangloss::Categories>,

=cut
