package Mojolicious::Plugin::Minion::Overview::Backend;
use Mojo::Base -base;

use Minion;

has 'db';

has 'minion' => sub { Minion->new }, weak => 1;

has 'query' => sub {{
    limit   => 25,
    page    => 1,
    where   => {},
    tags    => [],
    term    => '',
}};


sub clear_query {
    my $self = shift;

    $self->query({
        limit   => 25,
        page    => 1,
        where   => {},
        tags    => [],
        term    => '',
    });

    return $self;
}

sub job {
    my ($self, $id) = @_;

    return $self->minion->job($id);
}

sub limit {
    my ($self, $limit) = @_;

    $self->query->{ limit } = $limit;

    return $self;
}

sub page {
    my ($self, $page) = @_;

    $self->query->{ page } = $page;

    return $self;
}

sub search {
    my ($self, $term) = @_;

    $self->query->{ term } = $term;

    return $self;
}

sub tags {
    my ($self, $tags) = @_;

    push(@{ $self->query->{ tags } }, @$tags);

    return $self;
}

sub where {
    my $self = shift;
    my $field = shift;
    my $condition = shift;
    my $value = shift;

    $self->query->{ where }->{ $field } = $value || $condition;

    return $self;
}

1;
