package Orze::Drivers::Thumb;

use strict;
use warnings;

use Image::Thumbnail;
use File::Basename;
use File::Copy::Recursive qw/fcopy/;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::Thumb - Create a page by copying an image and making a thumbnail of it

=head1 DESCRIPTION

Create a page by copying an image from the C<data/> directory to the
C<www/> directory and creating a thumbnail with the same name prefixed
by C<thumb_>.

It takes care of the following attributes:

=over

=item format

The format for the thumbnail.

=item size

The size of the thumbnail.

=back

=head1 EXAMPLE

	<page name="media/poster"
          extension="pdf"
          format="png"
          size="200x300"
          driver="Thumb">
    </page>

This snippet of an xml project description copy the file
C<data/outputdir/media.pdf> to C<www/outputdir/media.pdf> and a
thumbnail of size 300x200 to the file C<www/outputdir/thumb_media.png>

=head1 SEE ALSO

Lookt at L<Image::Thumbnail> for the supported formats.

=head1 METHODS

=head2 process

Do the real processing

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};

    my $size = $page->att('size');
    my $format = $page->att('format');
    my $name = $page->att('name');
    my $extension = $page->att('extension');

    my ($source, $target) = $self->paths($name, $extension);
    fcopy($source, $target);

    my ($base, $directory, $suffix) = fileparse($name);
    my $output = $self->output($directory . "thumb_" . $base, $format);

    my $t = new Image::Thumbnail(
                          size       => $size,
                          create     => 1,
                          input      => $source,
                          outputpath => $output,
                          );
}

1;
