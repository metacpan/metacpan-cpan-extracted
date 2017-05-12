package Net::Gnip::ActivityStream;

use strict;
use base qw(Net::Gnip::BaseStream);
use Net::Gnip::Activity;

=head1 NAME

Net::Gnip::ActivityStream - represent a stream of Gnip Activities

=head1 SYNOPIS


    # Create a new stream    
    my $stream = Net::Gnip::ActivityStream->new();
    my $stream = Net::Gnip::ActivityStream->new(publisher => $publisher_name);

    # ... or parse from XML
    my $stream = Net::Gnip::ActivityStream->parse($xml);

    # set the activities
    $stream->activities(@activities);
    
    # get the activities 
    my @activities = $stream->activities;

    # or use an iterator
    while (my $activity = $stream->next) {
        print $activity->uid;
    }

    $stream->reset;

    # ... now you can use it again
    while (my $activity = $stream->next) {
        print $activity->uid;
    }
    



=head1 METHODS

=cut

=head2 new

Create a new, empty stream

=cut


=head2 publisher [publisher name]

Get or set the publisher name of this Activity Stream

=cut
sub publisher { shift->_do('publisher',@_) }


=head2 activities [activity[s]]

Get or set the activities

=cut

sub activities {
    my $self = shift;
    return $self->children(@_);
}

sub _child_name { 'activity' }

sub _elem_name  { 'activities' }


1;
