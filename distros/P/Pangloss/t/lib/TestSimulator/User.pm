package TestSimulator::User;

use strict;
use warnings;

use Benchmark qw( :all );
use Data::Random qw( rand_set rand_chars );
use Pangloss::Search::Request;

use base qw( TestSimulator::Base );

use constant ROLE => 'user';

sub get_collection_lists {
    my $self = shift;
    my $app  = $self->app;

    my $view = $app->language_editor->list;
    $app->user_editor->list_translators( $view );
    $app->user_editor->list_proofreaders( $view );
    $app->category_editor->list( $view );

    return $view;
}

sub choose_next_action {
    my $self = shift;
    return $self->prepare_action_search;
}

sub prepare_action_search {
    my $self = shift;
    my $view = $self->get_collection_lists;

    $self->emit( "($$) " .
		 @{$view->{languages}}    . ' langs, ' .
		 @{$view->{translators}}  . ' xlators, ' .
		 @{$view->{proofreaders}} . ' proofers, ' .
		 @{$view->{categories}}   . ' cats' );

    my @langs    = rand_set( set => $view->{languages} );
    my @xlators  = rand_set( set => $view->{translators} );
    my @proofers = rand_set( set => $view->{proofreaders} );
    my @cats     = rand_set( set => $view->{categories} );
    my $keyword  = join( '', rand_chars( max => 2, set => 'alpha' ) );

    my $sreq = Pangloss::Search::Request->new;
    $sreq->language( $_, 1 )    for @langs;
    $sreq->translator( $_, 1 )  for @xlators;
    $sreq->proofreader( $_, 1 ) for @proofers;
    $sreq->category( $_, 1 )    for @cats;

    $self->emit( "($$) searching [q='$keyword'" .
		 ', langs=' . join(',', map {$_->key} @langs) .
		 ', xlators=' . join(',', map {$_->key} @xlators) .
		 ', proofers=' . join(',', map {$_->key} @proofers) .
		 ', cats=' . join(',', map {$_->key} @cats) . ']' );

    $self->{sreq} = $sreq;

    return 'search';
}

sub action_search {
    my $self = shift;

    my $sreq  = delete $self->{sreq};
    my $view  = $self->app->searcher->search_terms( $sreq );
    my $pager = $view->{search_results_pager}
      || die "no search pager in view!";

    return $self;
}


1;
