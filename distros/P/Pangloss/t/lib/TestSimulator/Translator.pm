package TestSimulator::Translator;

use strict;
use warnings;

use Benchmark qw( :all );
use Data::Random qw( rand_set rand_chars rand_words );

use base qw( TestSimulator::Base );

use constant ROLE => 'translator';

sub get_translators {
    my $self = shift;
    my $app  = $self->app;

    my $view = $app->user_editor->list_translators;
    $app->user_editor->list_translators( $view );
    $app->user_editor->list_proofreaders( $view );
    $app->category_editor->list( $view );

    return $view;
}

sub choose_next_action {
    my $self = shift;
    return $self->prepare_action_translate;
}
sub prepare_action_translate {
    my $self = shift;

    my $term = $self->create_translation;
    $self->emit( "($$) adding term " . $term->name );

    $self->{term} = $term;

    return 'translate';
}

sub action_translate {
    my $self = shift;

    my $term = delete $self->{term};
    my $view = $self->app->term_editor->add( $term );

    return $self;
}

sub create_translation {
    my $self = shift;

    my $model   = $self->create_model;
    my $concept = $model->choose_random_concept;
    my $xlator  = $model->choose_random_translator;
    my $user    = $model->users->get( $xlator );
    my @langs   = keys %{ $user->privileges->translate_languages };

    my $term = Pangloss::Term->new
      ->concept( $concept )
      ->creator( $xlator )
      ->language( $langs[ int rand @langs ] )
      ->date( time )
      ->name( join( ' ', rand_words( max => 5 ) ) );

    return $term;
}

sub create_model {
    my $self = shift;

    $self->{model} =
      TestRandomizer->new
	->languages( $self->app->language_editor->get_or_create_collection )
	->users( $self->app->user_editor->get_or_create_collection )
	->concepts( $self->app->concept_editor->get_or_create_collection );
    # leave unnecessary terms & categories out for now...
    #->categories( $self->app->category_editor->get_or_create_collection )
    #->terms( $self->app->term_editor->get_or_create_collection );

    return $self->{model};
}

1;
