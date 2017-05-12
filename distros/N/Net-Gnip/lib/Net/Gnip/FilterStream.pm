package Net::Gnip::FilterStream;

use strict;
use base qw(Net::Gnip::BaseStream);
use Net::Gnip::Filter;

=head1 NAME

Net::Gnip::FilterStream - represent a list of Gnip Filters

=head1 SYNOPIS


    # Create a new stream    
    my $stream = Net::Gnip::FilterStream->new();

    # ... or parse from XML
    my $stream = Net::Gnip::FilterStream->parse($xml);

    # set the filters
    $stream->filters(@filters);
    
    # get the filters 
    my @filters = $stream->filters;

    # or use an iterator
    while (my $filter = $stream->next) {
        print $filter->name;
    }

    $stream->reset;

    # ... now you can use it again
    while (my $filter = $stream->next) {
        print $filter->name;
    }


=head1 METHODS

=cut

=head2 new

Create a new, empty stream

=cut

=head2 filters [filter[s]]

Get or set the filters

=cut

sub filters {
    my $self = shift;
    return $self->children(@_);
}

sub _child_name { 'filter' }

sub _elem_name  { 'filters' }
1;
