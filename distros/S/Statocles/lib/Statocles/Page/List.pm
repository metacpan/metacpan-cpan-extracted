package Statocles::Page::List;
our $VERSION = '0.094';
# ABSTRACT: A page presenting a list of other pages

use Statocles::Base 'Class';
with 'Statocles::Page';
use List::Util qw( reduce );
use Statocles::Template;
use Statocles::Page::ListItem;
use Statocles::Util qw( uniq_by );

#pod =attr pages
#pod
#pod The pages that should be shown in this list.
#pod
#pod =cut

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    init_arg => 'pages',
);

sub pages {
    my ( $self ) = @_;

    my %rewrite;
    if ( $self->type eq 'application/rss+xml' || $self->type eq 'application/atom+xml' ) {
        %rewrite = ( rewrite_mode => 'full' );
    }

    my @pages;
    for my $page ( @{ $self->_pages } ) {
        # Always re-wrap the page, even if it's already wrapped,
        # to change the rewrite_mode
        push @pages, Statocles::Page::ListItem->new(
            %rewrite,
            page => $page->isa( 'Statocles::Page::ListItem' ) ? $page->page : $page,
        );
    }

    return \@pages;
}

#pod =attr next
#pod
#pod The path to the next page in the pagination series.
#pod
#pod =attr prev
#pod
#pod The path to the previous page in the pagination series.
#pod
#pod =cut

has [qw( next prev )] => (
    is => 'rw',
    isa => PagePath,
    coerce => PagePath->coercion,
);

#pod =attr date
#pod
#pod Get the date of this list. By default, this is the latest date of the first
#pod page in the list of pages.
#pod
#pod =cut

has '+date' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        my $date = reduce { $a->epoch gt $b->epoch ? $a : $b }
                    map { $_->date }
                    @{ $self->pages };
        return $date;
    },
);

#pod =attr search_change_frequency
#pod
#pod Override the default L<search_change_frequency|Statocles::Page/search_change_frequency>
#pod to C<daily>, because these pages aggregate other pages.
#pod
#pod =cut

has '+search_change_frequency' => (
    default => sub { 'daily' },
);

#pod =attr search_priority
#pod
#pod Override the default L<search_priority|Statocles::Page/search_priority> to reduce
#pod the rank of list pages to C<0.3>.
#pod
#pod It is more important for users to get to the full page than
#pod to get to this list page, which may contain truncated content, and whose relevant
#pod content may appear 3-4 items down the page.
#pod
#pod =cut

has '+search_priority' => (
    default => sub { 0.3 },
);

#pod =method paginate
#pod
#pod     my @pages = Statocles::Page::List->paginate( %args );
#pod
#pod Build a paginated list of L<Statocles::Page::List> objects.
#pod
#pod Takes a list of key-value pairs with the following keys:
#pod
#pod     path    - An sprintf format string to build the path, like '/page-%i.html'.
#pod               Pages are indexed started at 1.
#pod     index   - The special, unique path for the first page. Optional.
#pod     pages   - The arrayref of Statocles::Page::Document objects to paginate.
#pod     after   - The number of items per page. Defaults to 5.
#pod
#pod Return a list of Statocles::Page::List objects in numerical order, the index
#pod page first (if any).
#pod
#pod =cut

sub paginate {
    my ( $class, %args ) = @_;

    # Unpack the args so we can pass the rest to new()
    my $after = delete $args{after} // 5;
    my $pages = delete $args{pages};
    my $path_format = delete $args{path};
    my $index = delete $args{index};

    # The date is the max of all input pages, since input pages get moved between
    # all the list pages
    my $date = reduce { $a->epoch gt $b->epoch ? $a : $b }
                map { $_->date }
                @$pages;

    my @sets;
    for my $i ( 0..$#{$pages} ) {
        push @{ $sets[ int( $i / $after ) ] }, $pages->[ $i ];
    }

    my @retval;
    for my $i ( 0..$#sets ) {
        my $path = $index && $i == 0 ? $index : sprintf( $path_format, $i + 1 );
        my $prev = $index && $i == 1 ? $index : sprintf( $path_format, $i );
        my $next = $i != $#sets ? sprintf( $path_format, $i + 2 ) : '';

        # Remove index.html from link URLs
        s{/index[.]html$}{/} for ( $prev, $next );

        push @retval, $class->new(
            path => $path,
            pages => $sets[$i],
            ( $next ? ( next => $next ) : () ),
            ( $i > 0 ? ( prev => $prev ) : () ),
            date => $date,
            %args,
        );
    }

    return @retval;
}

#pod =method vars
#pod
#pod     my %vars = $page->vars;
#pod
#pod Get the template variables for this page.
#pod
#pod =cut

around vars => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        pages => $self->pages,
    );
};

#pod =method links
#pod
#pod     my @links = $page->links( $key );
#pod
#pod Get the given set of links for this page. See L<the links
#pod attribute|Statocles::Page/links> for some commonly-used keys.
#pod
#pod For List pages, C<stylesheet> and C<script> links are also collected
#pod from the L<inner pages|/pages>, to ensure that content in those pages
#pod works correctly.
#pod
#pod =cut

around links => sub {
    my ( $orig, $self, @args ) = @_;

    if ( @args > 1 || $args[0] !~ /^(?:stylesheet|script)$/ ) {
        return $self->$orig( @args );
    }

    my @links;
    for my $page ( @{ $self->pages } ) {
        push @links, $page->links( @args );
    }
    push @links, $self->$orig( @args );
    return uniq_by { $_->href } @links;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Page::List - A page presenting a list of other pages

=head1 VERSION

version 0.094

=head1 DESCRIPTION

A List page contains a set of other pages. These are frequently used for index
pages.

=head1 ATTRIBUTES

=head2 pages

The pages that should be shown in this list.

=head2 next

The path to the next page in the pagination series.

=head2 prev

The path to the previous page in the pagination series.

=head2 date

Get the date of this list. By default, this is the latest date of the first
page in the list of pages.

=head2 search_change_frequency

Override the default L<search_change_frequency|Statocles::Page/search_change_frequency>
to C<daily>, because these pages aggregate other pages.

=head2 search_priority

Override the default L<search_priority|Statocles::Page/search_priority> to reduce
the rank of list pages to C<0.3>.

It is more important for users to get to the full page than
to get to this list page, which may contain truncated content, and whose relevant
content may appear 3-4 items down the page.

=head1 METHODS

=head2 paginate

    my @pages = Statocles::Page::List->paginate( %args );

Build a paginated list of L<Statocles::Page::List> objects.

Takes a list of key-value pairs with the following keys:

    path    - An sprintf format string to build the path, like '/page-%i.html'.
              Pages are indexed started at 1.
    index   - The special, unique path for the first page. Optional.
    pages   - The arrayref of Statocles::Page::Document objects to paginate.
    after   - The number of items per page. Defaults to 5.

Return a list of Statocles::Page::List objects in numerical order, the index
page first (if any).

=head2 vars

    my %vars = $page->vars;

Get the template variables for this page.

=head2 links

    my @links = $page->links( $key );

Get the given set of links for this page. See L<the links
attribute|Statocles::Page/links> for some commonly-used keys.

For List pages, C<stylesheet> and C<script> links are also collected
from the L<inner pages|/pages>, to ensure that content in those pages
works correctly.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
