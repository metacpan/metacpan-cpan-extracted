package Net::Gnip::PublisherStream;

use strict;
use base qw(Net::Gnip::BaseStream);
use Net::Gnip::Publisher;

=head1 NAME

Net::Gnip::PublisherStream - represent a list of Gnip Publisher

=head1 SYNOPIS


    # Create a new stream    
    my $stream = Net::Gnip::PublisherStream->new();

    # ... or parse from XML
    my $stream = Net::Gnip::FilterStream->parse($xml);

    # set the publishers
    $stream->publishers(@publisher);
    
    # get the publishers
    my @publishers = $stream->publishers;

    # or use an iterator
    while (my $publisher = $stream->next) {
        print $publisher->name;
    }

    $stream->reset;

    # ... now you can use it again
    while (my $publisher = $stream->next) {
        print $publisher->name;
    }

=head1 METHODS

=cut

=head2 new

Create a new, empty stream

=cut

=head2 publishers [publisher[s]]

Get or set the publishers

=cut

sub publishers {
    my $self = shift;
    return $self->children(@_);
}

sub _child_name { 'publisher' }

sub _elem_name  { 'publishers' }

1;
