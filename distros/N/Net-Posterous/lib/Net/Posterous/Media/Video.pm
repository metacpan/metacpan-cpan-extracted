package Net::Posterous::Media::Video;

use strict;
use base qw(Net::Posterous::Object);

use Class::Accessor "antlers";

=head1 NAME

Net::Posterous::Media::Video - represent an video object in Net::Posterous

=head1 METHODS

=cut


=head2 url 

Get or set the URL of this video.

=cut

has url => ( is => "rw", isa => "Str" );


=head2 thumb_url 

Get or set the URL of the thumbnail for this video.

=cut

sub thumb_url { 
    shift->thumb(@_);
}

has thumb => ( is => "rw", isa => "Str" );

=head2 filesize 

Get or set the filesize for this video.

=cut
has filesize => ( is => "rw", isa => "Str" );

=head2 flv

Get or set the URL to the flv transcoding for this video.

=cut

has flv => ( is => "rw", isa => "Str" );

=head2 mp4

Get or set the URL to the mp4 transcoding for this video.

=cut
has mp4 => ( is => "rw", isa => "Str" );

1;

