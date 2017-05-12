package Template::Flute::Paginator;

use strict;
use warnings;

use Moo;
use Sub::Quote;
use Template::Flute::Iterator;

=head1 NAME

Template::Flute::Paginator - Generic paginator class for Template::Flute

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

=cut

has iterator => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return Template::Flute::Iterator->new;},
);

has page_size => (
    is => 'rw',
    lazy => 1,
    default => quote_sub q{return 0;},
);

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

    $count = $self->iterator->count;

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

    unless (exists $self->{current_page}) {
        $self->{current_page} = 1;
    }

    return $self->{current_page};
}

=head2 select_page {

Select page, starting from 1.

=cut

sub select_page {
    my ($self, $page) = @_;
    my ($new_position, $distance);

    # calculate number of entries
    $new_position = ($page  - 1) * $self->page_size;

    $distance = $new_position - $self->page_position + $page - 2;

    if ($distance > 1) {
        for (0 .. $distance) {
            $self->next;
        }
    }
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
            return $self->iterator->next;
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

    $self->iterator->count;
}

=head2 seed

Seeds the iterator.

=cut

sub seed {
    my ($self, $data) = @_;

    $self->iterator->seed($data);
}

sub BUILDARGS {
    my ($class, @args) = @_;
    my ($iter, $data);

    if (ref($args[0]) eq 'ARRAY') {
        # create iterator
        $data = shift @args;
        $iter = Template::Flute::Iterator->new($data);
        unshift @args, iterator => $iter;
    }

    return {@args};
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Flute::Iterator>

=cut

1;
