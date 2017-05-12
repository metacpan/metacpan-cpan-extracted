=head1 NAME

Pangloss::Application::Searcher - searcher app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::Searcher;
  my $searcher = new Pangloss::Application::Searcher();

  my $view = $searcher->search_terms( $search_request );

=cut

package Pangloss::Application::Searcher;

use strict;
use warnings::register;

use Error qw( :try );

use Pangloss::Search;
use Pangloss::Search::Results::Pager;
use Pangloss::Application::View;

use base qw( Pangloss::Application::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];

sub search_terms {
    my $self     = shift;
    my $srequest = shift;
    my $pager    = shift;
    my $view     = shift || new Pangloss::Application::View;

    if ($srequest->modified or not defined $pager) {
	$self->_search_terms( $srequest, $view );
    } else {
	$self->emit( "using old pager: search request not modified" );
	$view->{search_results_pager} = $pager;
    }

    return $view;
}

sub _search_terms {
    my $self     = shift;
    my $srequest = shift;
    my $view     = shift;

    # make sure we have the relevant collections in the view:
    $self->parent->category_editor->list( $view ) unless $view->{categories_collection};
    $self->parent->language_editor->list( $view ) unless $view->{languages_collection};
    $self->parent->concept_editor->list( $view ) unless $view->{concepts_collection};
    $self->parent->user_editor->list( $view ) unless $view->{users_collection};

    my $search = Pangloss::Search->new
      ->categories( $view->{categories_collection} )
      ->concepts( $view->{concepts_collection} )
      ->languages( $view->{languages_collection} )
      ->users( $view->{users_collection} )
      ->terms( $self->parent->term_editor->get_or_create_collection->clone )
      ->add_filters( $srequest->get_filters );

    $search->apply;

    # doing a deep clone will be *SLOW* for a large number of results...
    # now Search.pm does the cloning...
    #my $results = $search->results->deep_clone;

    $view->{search_results_pager} =
      Pangloss::Search::Results::Pager->new
        ->order_by( 'concept', 'language' )
        ->results( $search->results );

    return $view;
}

1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Searcher application for Pangloss, inherits from L<Pangloss::Application::Base>.

=head1 METHODS

These methods throw an L<Error> if they cannot perform their jobs.  On success,
each returns a L<Pangloss::Application::View>.  If you pass in a view, the
results are added to it.

=over 4

=item $view = $obj->search_terms( $search_request, $pager [, $view ] )

search through the application's collection of terms by applying the
L<Pangloss::Search::Request> object given.

$pager must be a L<Pangloss::Search::Results::Pager> object, or undef.  If set,
and the search request has not been modified, it will re-use this object
instead of doing the search all over again.

sets $view->{search_results_pager}.

As a side-effect, the following collections are listed in the view if not
already present: I<categories>, I<languages>, I<concepts>, I<users>.  See the
relevant application editors for more details.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 NOTES

This was not written to be fast.  If speed becomes an issue, this will likely
need rethinking.

=head1 SEE ALSO

L<Pangloss::Application>, L<Pangloss::Search>, L<Pangloss::Search::Request>

=cut
