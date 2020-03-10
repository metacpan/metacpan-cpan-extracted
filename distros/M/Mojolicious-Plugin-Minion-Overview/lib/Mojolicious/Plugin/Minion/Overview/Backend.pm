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

has 'start' => 'CURDATE()';


=head2 clear_query

Clear the query fields

=cut

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

=head2 date

Set date

=cut

sub date {
    my ($self, $date) = @_;

    my $start = 'CURDATE()';

    if ($date eq 'Since yesterday') {
        $start = 'DATE_ADD(CURDATE(), INTERVAL -1 DAY)';
    } elsif ($date eq 'Last 3 days') {
        $start = 'DATE_ADD(CURDATE(), INTERVAL -3 DAY)';
    } elsif ($date eq 'Last 7 days') {
        $start = 'DATE_ADD(CURDATE(), INTERVAL -7 DAY)';
    } elsif ($date eq 'This month') {
        $start = 'LAST_DAY(CURDATE() + INTERVAL -1 MONTH) + INTERVAL 1 DAY';
    } elsif ($date eq 'Last 3 months') {
        $start = 'LAST_DAY(CURDATE() + INTERVAL -3 MONTH) + INTERVAL 1 DAY';
    }

    $self->start($start);

    return $self;
}

=head2 dashboard

Dashboard stats

=cut

sub dashboard {
    my $self = shift;

    return {
        overview    => $self->overview,
        workers     => $self->workers,
    };
}

=head2 job

Find a job by id

=cut

sub job {
    my ($self, $id) = @_;

    return $self->minion->job($id);
}

=head2 limit

Set the limit and return current instance

=cut

sub limit {
    my ($self, $limit) = @_;

    $self->query->{ limit } = $limit;

    return $self;
}

=head2 overview

Dashboard overview

=cut

sub overview {
    return [];
}

=head2 page

Set the page and return current instance

=cut

sub page {
    my ($self, $page) = @_;

    $self->query->{ page } = $page;

    return $self;
}

=head2 search

Set the search term and return current instance

=cut

sub search {
    my ($self, $term) = @_;

    $self->query->{ term } = $term;

    return $self;
}

=head2 tags

Set the search tags and return current instance

=cut

sub tags {
    my ($self, $tags) = @_;

    push(@{ $self->query->{ tags } }, @$tags);

    return $self;
}

=head2 when

Add where condition when first param is true

=cut

sub when {
    my ($self, $value, $field) = @_;

    if ($value) {
        $self->where($field, $value);
    }

    return $self;
}

=head2 where

Add a condition for a field and return current instance

=cut

sub where {
    my $self = shift;
    my $field = shift;
    my $condition = shift;
    my $value = shift;

    $self->query->{ where }->{ $field } = $value || $condition;

    return $self;
}

=head2 workers

Get workers information

=cut

sub workers {
    return [];
}

1;
