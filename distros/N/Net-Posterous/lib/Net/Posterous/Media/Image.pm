package Net::Posterous::Media::Image;

use strict;
use base qw(Net::Posterous::Object);

=head1 NAME

Net::Posterous::Media::Image - represent an image object in Net::Posterous

=head1 METHODS

=cut


=head2 url 

Get or set the url for this image.

=cut
sub url {
    shift->_do('medium','url', @_);
}

=head2 filesize

Get or set the filesize for this image.

=cut
sub filesize {
    shift->_do('medium','filesize', @_);
}

=head2 width 

Get or set the width for this image.

=cut
sub width {
   shift->_do('medium','width', @_);
}

=head2 height

Get or set the height for this image.

=cut
sub height {
    shift->_do('medium','height', @_);
}

=head2 thumb_url 

Get or set the URL to thumbnail for this image.

=cut
sub thumb_url {
    my $self = shift;
    shift->_do('thumb','url', @_);
}

=head2 thumb_width 

Get or set the width of the thumbnail for this image.

=cut
sub thumb_width {
    shift->_do('thumb','width', @_);
}

=head2 thumb_height

Get or set the height of the thumbnail for this image.

=cut
sub thumb_height {
    shift->_do('thumb','height', @_);
}

# we do this to normalise the methods for this object.
# Because the Posterous returned object is ... inconsistent
sub _do {
    my $self = shift;
    my $part = shift;
    my $key  = shift;
    $self->{$part}->{$key} = shift if @_;
    return $self->{$part}->{$key};
}
1;
