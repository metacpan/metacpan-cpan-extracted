package Reaction::UI::Controller::Collection::CRUD::Search;

use Moose;
BEGIN { extends 'Reaction::UI::Controller::Collection::CRUD'; }

use aliased 'Reaction::UI::ViewPort::SearchableListViewContainer';

use namespace::clean -except => 'meta';

override _build_action_viewport_map => sub {
    my ($self) = @_;

    my $map = super;

    $map->{list} = SearchableListViewContainer;

    return $map;
};

override _build_action_viewport_args => sub {
    my ($self) = @_;

    my $args = super;

    $args->{list}{layout} = 'searchable_list_view_container';

    return $args;
};

1;

__END__

=head1 NAME

Reaction::UI::Controller::Collection::CRUD::Search

=cut
