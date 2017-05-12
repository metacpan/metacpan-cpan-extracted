package Net::CoverArtArchive::CoverArt;
{
  $Net::CoverArtArchive::CoverArt::VERSION = '1.02';
}
# ABSTRACT: A single cover art image

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;

coerce 'Bool', from class_type('JSON::XS::Boolean'), via { $_ ? 1 : 0 };

has id => (
    isa => 'Int',
    is => 'ro',
    required => 1
);

has types => (
    isa => 'ArrayRef[Str]',
    is => 'ro',
);

has is_front => (
    isa => 'Bool',
    is => 'ro',
    init_arg => 'front',
    coerce => 1
);

has is_back => (
    isa => 'Bool',
    is => 'ro',
    init_arg => 'back',
    coerce => 1
);

has comment => (
    isa => 'Str',
    is => 'ro',
);

has image => (
    isa => 'Str',
    is => 'ro',
);

has large_thumbnail => (
    isa => 'Str',
    is => 'ro',
);

has small_thumbnail => (
    isa => 'Str',
    is => 'ro',
);

has approved => (
    isa => 'Bool',
    is => 'ro',
    coerce => 1
);

has edit => (
    isa => 'Str',
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;


=pod

=encoding utf-8

=head1 NAME

Net::CoverArtArchive::CoverArt - A single cover art image

=head1 ATTRIBUTES

=head2 id

The ID of this cover art. Fairly internal, you probably don't need to do
anything with this.

=head2 types

An array reference of strings, where each string describes the type of this
image. For example, an image might be about a specific medium, or it might be a
page in a booklet.

=head2 is_front

Whether this image is considered to be the 'frontiest' image of a release.

=head2 is_back

Whether this image is considered to be the 'backiest' image of a release.

=head2 comment

A string potentially describing additionally information about this image. Free
text and unstructured.

=head2 image

The full URL of the image

=head2 large_thumbnail

A URL to the large thumbnail of this image.

=head2 small_thumbnail

A URL to the small thumbnail of this image.

=head2 approved

Whether this image has passed peer review.

=head2 edit

A URL to the MusicBrainz edit that originally added this piece of artwork.

=head1 AUTHORS

=over 4

=item *

Oliver Charles <oliver@musicbrainz.org>

=item *

Brian Cassidy <bricas@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver@musicbrainz.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

