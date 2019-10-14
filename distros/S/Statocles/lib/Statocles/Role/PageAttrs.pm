package Statocles::Role::PageAttrs;
our $VERSION = '0.095';
# ABSTRACT: A role implementing common attributes for pages/documents

use Statocles::Base 'Role';
use Statocles::Util qw( uniq_by );
use Statocles::Person;

#pod =attr title
#pod
#pod The title of the page. Any unsafe characters in the title (C<E<lt>>,
#pod C<E<gt>>, C<">, and C<&>) will be escaped by the template, so no HTML
#pod allowed.
#pod
#pod =cut

has title => (
    is => 'rw',
    isa => Str,
    default => '',
);

#pod =attr author
#pod
#pod The author of the page.
#pod
#pod =cut

has author => (
    is => 'rw',
    isa => Maybe[PersonType],
    coerce => PersonType->coercion,
    lazy => 1,
    builder => '_build_author',
);

sub _build_author {
    my ( $self ) = @_;
    return $self->site->author || Statocles::Person->new( name => '' );
}

#pod =attr links
#pod
#pod A hash of arrays of links to pages related to this page. Possible keys:
#pod
#pod     feed        - Feed pages related to this page
#pod     alternate   - Alternate versions of this page posted to other sites
#pod     stylesheet  - Additional stylesheets for this page
#pod     script      - Additional scripts for this page
#pod
#pod Each item in the array is a L<link object|Statocles::Link>. The most common
#pod attributes are:
#pod
#pod     text        - The text of the link
#pod     href        - The page for the link
#pod     type        - The MIME type of the link, optional
#pod
#pod =cut

has _links => (
    is => 'ro',
    isa => LinkHash,
    lazy => 1,
    default => sub { +{} },
    coerce => LinkHash->coercion,
    init_arg => 'links',
);

#pod =attr images
#pod
#pod A hash of images related to this page. Each value should be an L<image
#pod object|Statocles::Image>.  These are used by themes to show images next
#pod to articles, thumbnails, and/or shortcut icons.
#pod
#pod =cut

has _images => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Image']],
    lazy => 1,
    default => sub { +{} },
    init_arg => 'images',
    coerce => sub {
        my ( $ref ) = @_;
        my %img;
        for my $name ( keys %$ref ) {
            my $attrs = $ref->{ $name };
            if ( !ref $attrs ) {
                $attrs = { src => $attrs };
            }
            $img{ $name } = Statocles::Image->new(
                %{ $attrs },
            );
        }
        return \%img;
    },
);

#pod =method links
#pod
#pod     my @links = $page->links( $key );
#pod     my $link = $page->links( $key );
#pod     $page->links( $key => $add_link );
#pod
#pod Get or append to the links set for the given key. See L<the links
#pod attribute|/links> for some commonly-used keys.
#pod
#pod If only one argument is given, returns a list of L<link
#pod objects|Statocles::Link>. In scalar context, returns the first link in
#pod the list.
#pod
#pod If two or more arguments are given, append the new links to the given
#pod key. C<$add_link> may be a URL string, a hash reference of L<link
#pod attributes|Statocles::Link/ATTRIBUTES>, or a L<Statocles::Link
#pod object|Statocles::Link>. When adding links, nothing is returned.
#pod
#pod =cut

sub links {
    my ( $self, $name, @add_links ) = @_;
    if ( @add_links ) {
        push @{ $self->_links->{ $name } }, map { LinkType->coerce( $_ ) } @add_links;
        return;
    }
    return $self->_links if !$name;
    my @links = uniq_by { $_->href }
        $self->_links->{ $name } ? @{ $self->_links->{ $name } } : ();
    return wantarray ? @links : $links[0];
}

#pod =method images
#pod
#pod     my $image = $page->images( $key );
#pod
#pod Get the images for the given key. See L<the images attribute|/images> for some
#pod commonly-used keys. Returns an L<image object|Statocles::Image>.
#pod
#pod =cut

sub images {
    my ( $self, $name ) = @_;
    # This exists here as a placeholder in case we ever need to handle
    # arrays of images, which I anticipate will happen when we build
    # image galleries or want to be able to pick a single random image
    # from an array.
    return $name ? $self->_images->{ $name } : $self->_images;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Role::PageAttrs - A role implementing common attributes for pages/documents

=head1 VERSION

version 0.095

=head1 ATTRIBUTES

=head2 title

The title of the page. Any unsafe characters in the title (C<E<lt>>,
C<E<gt>>, C<">, and C<&>) will be escaped by the template, so no HTML
allowed.

=head2 author

The author of the page.

=head2 links

A hash of arrays of links to pages related to this page. Possible keys:

    feed        - Feed pages related to this page
    alternate   - Alternate versions of this page posted to other sites
    stylesheet  - Additional stylesheets for this page
    script      - Additional scripts for this page

Each item in the array is a L<link object|Statocles::Link>. The most common
attributes are:

    text        - The text of the link
    href        - The page for the link
    type        - The MIME type of the link, optional

=head2 images

A hash of images related to this page. Each value should be an L<image
object|Statocles::Image>.  These are used by themes to show images next
to articles, thumbnails, and/or shortcut icons.

=head1 METHODS

=head2 links

    my @links = $page->links( $key );
    my $link = $page->links( $key );
    $page->links( $key => $add_link );

Get or append to the links set for the given key. See L<the links
attribute|/links> for some commonly-used keys.

If only one argument is given, returns a list of L<link
objects|Statocles::Link>. In scalar context, returns the first link in
the list.

If two or more arguments are given, append the new links to the given
key. C<$add_link> may be a URL string, a hash reference of L<link
attributes|Statocles::Link/ATTRIBUTES>, or a L<Statocles::Link
object|Statocles::Link>. When adding links, nothing is returned.

=head2 images

    my $image = $page->images( $key );

Get the images for the given key. See L<the images attribute|/images> for some
commonly-used keys. Returns an L<image object|Statocles::Image>.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
