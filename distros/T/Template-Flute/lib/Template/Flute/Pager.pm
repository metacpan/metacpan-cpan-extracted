package Template::Flute::Pager;

use strict;
use warnings;

use Moo;
use Sub::Quote;

=head1 NAME

Template::Flute::Pager - Data::Page class for Template::Flute

=head1 SYNOPSIS

    $paginator = Template::Flute::Paginator->new;

    # set page size
    $paginator->page_size(10);

    # retrieve number of pages
    $paginator->pages;

    # retrieve current page (starting with 1)
    $paginator->current_page;

    # retrieve global position numbers for current page
    $paginator->position_first;
    $paginator->position_last;

    # select a page (starting with 1)
    $paginator->select_page;

=head1 ATTRIBUTES

=head2 iterator

Pager iterator.

=cut

has iterator => (
    is => 'rw',
    lazy => 1,
#    default => quote_sub q{return Data::Pager->new;},
);

=head2 page_size

Page size (defaults to 0).

=cut

has page_size => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

=head2 page_position

Page position (defaults to 0).

=cut

has page_position => (
    is => 'ro',
    lazy => 1,
    default => quote_sub q{return 0;},
);

=head1 METHODS

=head2 pages

Returns number of pages.

=cut

sub pages {
    my $self = shift;
    my ($count, $pages);

    $count = $self->iterator->total_entries;

    if ($self->page_size > 0) {
        $pages = int($count / $self->page_size);
        if ($count % $self->page_size) {
            $pages++;
        }
    }
    elsif ($count > 0) {
        $pages = 1;
    }
    else {
        $pages = 0;
    }

    return $pages;
}

=head2 current_page

Returns current page, starting from 1.

=cut

sub current_page {
    my $self = shift;

    $self->iterator->current_page;
}

=head2 select_page {

Select page, starting from 1.

=cut

sub select_page {
    my ($self, $page) = @_;
    my ($new_position, $distance);

    $self->iterator->current_page($page);
}

=head2 position_first

=cut

sub position_first {
    my $self = shift;

    return ($self->current_page - 1) * $self->page_size + 1;
}

=head2 position_last

=cut

sub position_last {
    my $self = shift;
    my $position;

    $position = $self->current_page * $self->page_size;

    if ($position > $self->count) {
        $position = $self->count;
    }

    return $position;
}

=head2 next

Returns next record or undef.

=cut

sub next {
    my $self = shift;

    if ($self->page_size > 0) {
        if ($self->page_position < $self->page_size) {
            $self->{page_position}++;
            return $self->iterator->next_page;
        }
        else {
            # advance current page
            $self->{current_page}++;
            $self->{page_position} = 0;
            return;
        }
    }
    else {
        return $self->iterator->next;
    }
}

=head2 count

Returns number of records.

=cut

sub count {
    my $self = shift;

    $self->iterator->total_entries;
}

=head2 reset

Resets iterator.

=cut

sub reset {
    my $self = shift;

    $self->iterator->current_page(1);
}

=head2 seed

Seeds the iterator.

=cut

sub seed {
    my ($self, $data) = @_;

    $self->iterator->seed($data);
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Flute::Iterator>

=cut

1;
