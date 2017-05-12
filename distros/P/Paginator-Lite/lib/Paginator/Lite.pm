package Paginator::Lite;
$Paginator::Lite::VERSION = '2.001003';
use strict;
use warnings;

use Moo;
use URI;

has curr => (
    required => 1,
    is       => 'ro',
    isa      => sub { die "curr page must be > 0" unless $_[0] > 0 },
);

has frame_size => (
    required => 1,
    is       => 'ro',
    isa      => sub { die "frame_size must be >= 0" unless $_[0] >= 0 },
);

has page_size => (
    required => 1,
    is       => 'ro',
    isa      => sub { die "page_size must be > 0" unless $_[0] > 0 },
);

has items => (
    required => 1,
    is       => 'ro',
    isa      => sub { die "items must be > 0" unless $_[0] >= 0 },
);

has base_url => (
    required => 1,
    is       => 'ro',
    isa      => sub { die "base_url must be defined" unless defined $_[0] },
);

has mode => (
    is      => 'ro',
    default => sub { 'path' },
    isa     => sub {
        my $mode = shift;
        die "mode must be 'path' or 'query'" unless $mode =~ /path|query/;
    },
);

has first => ( is => 'ro' );

has prev => ( is => 'ro' );

has begin => ( is => 'ro' );

has end => ( is => 'ro' );

has next => ( is => 'ro' );

has last => ( is => 'ro' );

has params => ( is => 'ro' );

sub BUILD {
    my ($self) = @_;

    $self->{first} = 1;

    $self->{last} = _ceil( $self->items / $self->page_size );

    $self->{curr} = $self->{last} if $self->{curr} > $self->{last};

    $self->{prev} =
      $self->{curr} == $self->{first}
      ? 1
      : $self->{curr} - 1;

    $self->{next} =
        $self->{curr} == $self->{last}
      ? $self->{last}
      : $self->{curr} + 1;

    if ( $self->frame_size > 0 ) {
        my $half_frame = int( 0.5 + $self->frame_size / 2 );

        $self->{begin} = $self->curr - $half_frame + 1;
        $self->{begin} = $self->{first} if $self->{begin} < $self->{first};

        $self->{end} = $self->curr + $half_frame - 1;
        $self->{end} = $self->{last} if $self->{end} > $self->{last};
    }
    else {
        $self->{begin} = 0;
        $self->{end}   = -1;
    }
}

sub first_url { $_[0]->_custom_url( $_[0]->first ) }
sub prev_url  { $_[0]->_custom_url( $_[0]->prev ) }
sub curr_url  { $_[0]->_custom_url( $_[0]->curr ) }
sub next_url  { $_[0]->_custom_url( $_[0]->next ) }
sub last_url  { $_[0]->_custom_url( $_[0]->last ) }
sub page_url  { $_[0]->_custom_url( $_[1] ) }

sub _custom_url {
    my ( $self, $page ) = @_;

    my $uri = URI->new( $self->base_url );

    if ( $self->mode eq 'path' ) {
        return $uri->path . '/' . $page;
    }
    else {
        my $params = $self->params;
        $params->{page} = $page;
        $uri->query_form($params);
        return $uri->as_string;
    }
}

sub _ceil {
    my ( $val, $floor ) = @_;

    $floor = int $val;

    return $floor == $val ? $floor : $floor + 1;
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Paginator::Lite

=head1 VERSION

version 2.001003

=head1 SYNOPSIS

A simple tool to automate the creation of paging links

    use Paginator::Lite;
    
    my $paginator = Paginator::Lite->new({
        curr        => 3,
        items       => 65,
        frame_size  => 5,
        page_size   => 10, 
        base_url    => '/foo/items',
        mode        => 'query',
        params      => {
            bar => 123
        },
    });
    
    ...
    
    $paginator->first       # 1
    $paginator->last        # 7
    $paginator->begin       # 1
    $paginator->end         # 5
    $paginator->next        # 4
    $paginator->prev        # 2
    $paginator->base_url    # '/foo/items'

    $paginator->first_url   # '/foo/items?bar=123&page=1'
    $paginator->prev_url    # '/foo/items?bar=123&page=2'
    $paginator->curr_url    # '/foo/items?bar=123&page=3'
    $paginator->next_url    # '/foo/items?bar=123&page=4'
    $paginator->last_url    # '/foo/items?bar=123&page=7'

=head1 DESCRIPTION

When handle with huge amounts of data sometimes you want to display only a
portion of it and provide controls to naviagte through it.

The classic way is to provide links or buttons to next, previous and some
pages around the current page, like this:

    (prev)  1 2 [3] 4 5 (next)

But when the number of pages grow up too much this approach may be annoying:

    (prev) 1 2 3 4 5 6 7 8 9 10 [11] 12 13 14 15 16 16 18 19 20 21 (next)

So Paginator::Lite helps you calculating the numbers to feed your view loops
and implements the concept of frame. A frame is a small portion of pages
around the current page that will be displayed in addition to (prev), (next)
and other permanent buttons:

    (prev) 10 11 12 [13] 14 15 16 (next)
            \                  /
              ----- frame ----
                7 of 21 pages

=head1 NAME

Paginator::Lite - A simple paginator

=head1 VERSION

2.1.0

=head1 METHODS

=head2 new

Creates a Paginator::Lite object.

You must provide all required arguments: C<base_url>, C<curr>, C<frame_size>,
C<items> and C<page_size>.

C<params> is a optional argument that may be used to pass arbitrary data.

See more details about them in documentation of their respective
accessors.

=head2 base_url

Returns the value of C<base_url>. It is the same value that you must supply
to constructor. This value will be used by the template to build the links to
direct pages.

=head2 curr

Returns the value of B<current page>. It is the same value that you must
supply to constructor.

=head2 frame_size

Returns the value of C<frame_size>. It is the same value that you must supply
to constructor. It is also the number of pages visible around current page.

Usually C<frame_size> may be calculated by:

    my $frame_size = $pag->end - $pag->begin + 1

However when current page is too close to C<first> or C<last>, the frame may
be deformed but still trying to center in the current page.

=head2 page_size

Returns the value of C<page_size>. It is the same value that you must supply
to constructor and means the number of items that you want display in a
single page.

=head2 items

Returns the value of C<items>. It is the same value the you must provide to
constructor and means the total number of items that you are paginating.

=head2 first

Returns the value of the first page, usually B<1>.

=head2 last

Returns the value of the last page. This value is calculated by dividing the
total amount of items by the number of items per page and then rounding up
the result.

    $self->{last} = ceil( $self->items / $self->page_size );

=head2 begin

Returns the value of the first page of current frame. Usually you will
iterate between C<begin> and C<end> in your view to create direct links to
those pages.

=head2 end

Returns the value of the last page of current frame.

=head2 prev

Returns the value of previous page. Usually this value is C<curr - 1>, except
when current page is B<1>.

=head2 next

Returns the value of next page. Usually this value is C<curr + 1>, except
when current page is C<last>.

=head2 params

Returns arbitrary data passed to contructor by C<params> argument.

=head2 mode

Returns the chosen mode (path or query) of resulting URLs.

=head2 first_url

Returns the URL of the first page.

=head2 prev_url

Returns the URL of the previous page.

=head2 curr_url

Returns the URL of the current page.

=head2 next_url

Returns the URL of the next page.

=head2 last_url

Returns the URL of the last page.

=head2 page_url( $page )

Returns the URL of given page.

=head2 BUILD

Private. It casts the magic when building the object.

=head1 AUTHOR

Blabos de Blebe, C<< <blabos at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-paginator-lite at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Paginator-Lite>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Paginator::Lite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Paginator-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Paginator-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Paginator-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/Paginator-Lite/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Blabos de Blebe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information. 

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
