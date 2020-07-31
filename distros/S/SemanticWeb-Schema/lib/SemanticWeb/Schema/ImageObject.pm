use utf8;

package SemanticWeb::Schema::ImageObject;

# ABSTRACT: An image file.

use Moo;

extends qw/ SemanticWeb::Schema::MediaObject /;


use MooX::JSON_LD 'ImageObject';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has caption => (
    is        => 'rw',
    predicate => '_has_caption',
    json_ld   => 'caption',
);



has exif_data => (
    is        => 'rw',
    predicate => '_has_exif_data',
    json_ld   => 'exifData',
);



has representative_of_page => (
    is        => 'rw',
    predicate => '_has_representative_of_page',
    json_ld   => 'representativeOfPage',
);



has thumbnail => (
    is        => 'rw',
    predicate => '_has_thumbnail',
    json_ld   => 'thumbnail',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ImageObject - An image file.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

An image file.

=head1 ATTRIBUTES

=head2 C<caption>

=for html <p>The caption for this object. For downloadable machine formats (closed
caption, subtitles etc.) use MediaObject and indicate the <a
class="localLink"
href="http://schema.org/encodingFormat">encodingFormat</a>.<p>

A caption should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=item C<Str>

=back

=head2 C<_has_caption>

A predicate for the L</caption> attribute.

=head2 C<exif_data>

C<exifData>

exif data for this object.

A exif_data should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=item C<Str>

=back

=head2 C<_has_exif_data>

A predicate for the L</exif_data> attribute.

=head2 C<representative_of_page>

C<representativeOfPage>

Indicates whether this image is representative of the content of the page.

A representative_of_page should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_representative_of_page>

A predicate for the L</representative_of_page> attribute.

=head2 C<thumbnail>

Thumbnail image for an image or video.

A thumbnail should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<_has_thumbnail>

A predicate for the L</thumbnail> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MediaObject>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
