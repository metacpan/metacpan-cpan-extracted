package Net::Google::PicasaWeb::Media;
{
  $Net::Google::PicasaWeb::Media::VERSION = '0.12';
}
use Moose;

# ABSTRACT: hold information about a photo or video

extends 'Net::Google::PicasaWeb::Base';

use Carp;


has title => (
    is         => 'rw',
    isa        => 'Str',
);


has description => (
    is          => 'rw',
    isa         => 'Str',
);


has content => (
    is          => 'rw',
    isa         => 'Net::Google::PicasaWeb::Media::Content',
);


has thumbnails => (
    is          => 'rw',
    isa         => 'ArrayRef[Net::Google::PicasaWeb::Media::Thumbnail]',
    auto_deref  => 1,
);


sub from_feed {
    my ($class, $service, $media_group) = @_;

    my $content = $media_group->first_child('media:content');

    my %params = (
        service     => $service,
        twig        => $media_group,
        title       => $media_group->field('media:title'),
        description => $media_group->field('media:description'),
    );       
    
    my $self = $class->new(\%params);

    $self->content(
        Net::Google::PicasaWeb::Media::Content->new(
            media     => $self,
            url       => $content->att('url'),
            mime_type => $content->att('type'),
            medium    => $content->att('medium'),

            ($content->att('height')   ? (height => $content->att('height'))   : ()),
            ($content->att('width')    ? (width  => $content->att('width'))    : ()),
            ($content->att('fileSize') ? (size   => $content->att('fileSize')) : ()),
        )
    );
    $self->thumbnails(
        [
            map { 
                Net::Google::PicasaWeb::Media::Thumbnail->new(
                    media  => $self,
                    url    => $_->att('url'),

                    ($_->att('height') ? (height => $_->att('height')) : ()),
                    ($_->att('width')  ? (width  => $_->att('width'))  : ()),
                )
            } $media_group->children('media:thumbnail')
        ]
    );

    return $self;
}

sub _fetch {
    my ($self, $content, %params) = @_;
    my $url = $content->url;

    my %header;
    $header{':content_file'} = $params{file} if $params{file};

    my $response = $self->service->user_agent->get($url, %header);

    if ($response->is_success) {
        return $response->content;
    }
    else {
        croak $response->status_line;
    }
}

package Net::Google::PicasaWeb::Media::Content;
{
  $Net::Google::PicasaWeb::Media::Content::VERSION = '0.12';
}
use Moose;


has media => (
    is          => 'rw',
    isa         => 'Net::Google::PicasaWeb::Media',
    required    => 1,
    weak_ref    => 1,
);


has url => (
    is          => 'rw',
    isa         => 'Str',
);


has mime_type => (
    is         => 'rw',
    isa        => 'Str',
);


has medium => (
    is          => 'rw',
    isa         => 'Str',
);


has width => (
    is          => 'rw', 
    isa         => 'Int',
);


has height => (
    is          => 'rw',
    isa         => 'Int',
);


has size => (
    is          => 'rw',
    isa         => 'Int',
);


sub fetch {
    my $self = shift;
    return $self->media->_fetch($self, @_);
}

package Net::Google::PicasaWeb::Media::Thumbnail;
{
  $Net::Google::PicasaWeb::Media::Thumbnail::VERSION = '0.12';
}
use Moose;


has media => (
    is          => 'rw',
    isa         => 'Net::Google::PicasaWeb::Media',
    required    => 1,
    weak_ref    => 1,
);


has url => (
    is          => 'rw',
    isa         => 'Str',
);


has width => (
    is          => 'rw',
    isa         => 'Int',
);


has height => (
    is          => 'rw',
    isa         => 'Int',
);


sub fetch {
    my $self = shift;
    return $self->media->_fetch($self, @_);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::Google::PicasaWeb::Media - hold information about a photo or video

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  my @photos = $album->list_media_entries;
  for my $photo (@photos) {
      my $media_info = $photo->photo;

      print "Image Title: ", $media_info->title, "\n";
      print "Image Description: ", $media_info->description, "\n\n";

      my $main_photo = $media_info->content;
      print "Image URL: ", $main_photo->url, "\n";
      print "Image MIME Type: ", $main_photo->mime_type, "\n";
      print "Image Medium: ", $main_photo->medium, "\n";

      print "Thumbnails:\n\n";
      
      for my $thumbnail ($media_info->thumbnails) {
          print "    Thumbnail URL: ", $thumbnail->url, "\n";
          print "    Thumbnail Dimensions: ", 
              $thumbnail->width, "x", $thumbnail->height, "\n\n";

          my $photo_data = $thumbnail->fetch;
          $thumbnail->fetch( file => 'thumbnail.jpg' );
      }
    
      my $photo_data = $main_photo->fetch;
      $main_photo->fetch( file => 'photo.jpg' );
  }

=head1 DESCRIPTION

This is where you will find information about the photos, videos, and thumbnails themselves. You can get information about them with this object, such as the URL that can be used to download the media file. This object (and its children) also provide some features to fetching this information.

This class extends L<Net::Google::PicasaWeb::Base>.

=head1 ATTRIBUTE

=head2 title

This is the title of the photo or video.

=head2 description

This is a description for the photo or video.

=head2 content

This is the main photo or video item attached to the media information entry. See L</MEDIA CONTENT> below for information about the object returned.

=head2 thumbnails

This is an array of object containing information about the thumbnails that were attached when the photo was retrieved from the server.  See L</THUMBNAILS> below for information about these objects.

=head1 METHODS

=head2 from_feed

Builds a media class from a service object and reference to a C<< <media:group> >> object in L<XML::Twig::Elt>.

=head1 MEDIA CONTENT

The object returned from the L</content> accessor is an object with the following accessors and methods.

=head2 ATTRIBUTES

=head3 media

This is the parent L<Net::Google::PicasaWeb::Media> object.

=head3 url

This is the URL where the photo or video may be downloaded from.

=head3 mime_type

This is the MIME-Type of the photo or video.

=head3 medium

This should be one of the following scalar values describing the media entry:

=over

=item *

image

=item *

video

=back

=head3 width

The width of the photo in pixels.

=head3 height

The height of the photo in pixels.

=head3 size

The file size of the photo in bytes.

=head1 METHODS

=head2 fetch

  my $data = $content->fetch(%params);

Fetches the image or video from Picasa Web. By default, this method returns the file data as a scalar.

This method accepts the following parameters, which modify this behavior:

=over

=item file

If given, the data will not be returned, but saved to the named file instead.

=back

=head1 THUMBNAILS

Each thumbnail returned represents an individual image resource used as a thumbnail for the main item. Each one has the following attributes and methods.

=head2 ATTRIBUTES

=head3 media

This is the parent L<Net::Google::PicasaWeb::Media> object.

=head3 url

This is the URL where the thumbnail image can be pulled down from.

=head3 width

This is the pixel width of the image.

=head3 height

This is the pixel height of the image.

=head1 METHODS

=head2 fetch

  my $data = $thumbnail->fetch(%params);

Fetches the thumbnail image from Picasa Web. By default, this method returns the image data as a scalar.

This method accepts the following parameters, which modify this behavior:

=over

=item file

If given, the data will not be returned, but saved to the named file instead.

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
