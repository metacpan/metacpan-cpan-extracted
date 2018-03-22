package Statocles::Image;
our $VERSION = '0.088';
# ABSTRACT: A reference to an image

#pod =head1 SYNOPSIS
#pod
#pod     my $img = Statocles::Image->new(
#pod         src     => '/path/to/image.jpg',
#pod         alt     => 'Alternative text',
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class holds a link to an image, and the attributes required to
#pod render its markup. This is used by L<documents|Statocles::Document/images>
#pod to associate images with the content.
#pod
#pod =cut

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );

#pod =attr src
#pod
#pod The source URL of the image. Required.
#pod
#pod =cut

has src => (
    is => 'rw',
    isa => Str,
    required => 1,
    coerce => sub {
        my ( $href ) = @_;
        if ( blessed $href && $href->isa( 'Path::Tiny' ) ) {
            return $href->stringify;
        }
        return $href;
    },
);

#pod =attr alt
#pod
#pod The text to display if the image cannot be fetched or rendered. This is also
#pod the text to use for non-visual media.
#pod
#pod If missing, the image is presentational only, not content.
#pod
#pod =cut

has alt => (
    is => 'rw',
    isa => Str,
    default => sub { '' },
);

#pod =attr width
#pod
#pod The width of the image, in pixels.
#pod
#pod =cut

has width => (
    is => 'rw',
    isa => Int,
);

#pod =attr height
#pod
#pod The height of the image, in pixels.
#pod
#pod =cut

has height => (
    is => 'rw',
    isa => Int,
);

#pod =attr role
#pod
#pod The L<ARIA|http://www.w3.org/TR/wai-aria/> role for this image. If the L</alt>
#pod attribute is empty, this attribute defaults to C<"presentation">.
#pod
#pod =cut

has role => (
    is => 'rw',
    isa => Maybe[Str],
    lazy => 1,
    default => sub {
        return !$_[0]->alt ? 'presentation' : undef;
    },
);

#pod =attr data
#pod
#pod A hash of arbitrary data available to theme templates. This is a good place to
#pod put extra structured data like image credits, copyright, or location.
#pod
#pod =cut

has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Image - A reference to an image

=head1 VERSION

version 0.088

=head1 SYNOPSIS

    my $img = Statocles::Image->new(
        src     => '/path/to/image.jpg',
        alt     => 'Alternative text',
    );

=head1 DESCRIPTION

This class holds a link to an image, and the attributes required to
render its markup. This is used by L<documents|Statocles::Document/images>
to associate images with the content.

=head1 ATTRIBUTES

=head2 src

The source URL of the image. Required.

=head2 alt

The text to display if the image cannot be fetched or rendered. This is also
the text to use for non-visual media.

If missing, the image is presentational only, not content.

=head2 width

The width of the image, in pixels.

=head2 height

The height of the image, in pixels.

=head2 role

The L<ARIA|http://www.w3.org/TR/wai-aria/> role for this image. If the L</alt>
attribute is empty, this attribute defaults to C<"presentation">.

=head2 data

A hash of arbitrary data available to theme templates. This is a good place to
put extra structured data like image credits, copyright, or location.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
