package Net::Posterous::Media;

use strict;
use base qw(Net::Posterous::Object);

use Net::Posterous::Media::Image;
use Net::Posterous::Media::Video;
use Net::Posterous::Media::Audio;
use Net::Posterous::Media::Local;


=head1 NAME

Net::Posterous::Media - represent a media object in Net::Posterous

=head1 METHODS

=cut

=head2 new

Returns either a C<Net::Posterous::Media::Image>, C<Net::Posterous::Media::Audio> or C<Net::Posterous::Media::Video> object.
 
=cut

sub new {
   my $class = shift;
   my %opts  = @_;
   # Create the new class name and instantiate it
   my $type  = delete $opts{type};
   my $sub   = $class."::".ucfirst($type);
   return bless \%opts, $sub;
}


1;