package Net::Posterous::Media::Audio;

use strict;
use base qw(Net::Posterous::Object);

use Class::Accessor "antlers";

=head1 NAME

Net::Posterous::Media::Audio - represent an audio object in Net::Posterous

=head1 METHODS

=cut

=head2 url 

Get or set the url for this Audio object.

=cut

has url => ( is => "rw", isa => "Str" );


=head2 filesize 

Get or set the filesize for this Audio object.

=cut
has filesize => ( is => "rw", isa => "Str" );

1;