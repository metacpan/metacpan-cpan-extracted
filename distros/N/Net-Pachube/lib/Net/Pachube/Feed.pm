use strict;
use warnings;
package Net::Pachube::Feed;
BEGIN {
  $Net::Pachube::Feed::VERSION = '1.102900';
}

# ABSTRACT: Perl extension for manipulating pachube.com feeds


use 5.006;
use base qw/Class::Accessor::Fast/;
use Carp;
use XML::Simple;

__PACKAGE__->mk_accessors(qw/id pachube eeml/);


sub new {
  my $pkg = shift;
  my %p = @_;
  my $self = $pkg->SUPER::new(\%p);
  $p{fetch} ? $self->get() : $self;
}


sub get {
  my ($self) = @_;
  my $pachube = $self->pachube;
  my $url = $pachube->url.'/'.$self->id.'.xml';
  my $resp = $pachube->_request(method => 'GET', url => $url) or return;
  $self->{eeml} = $resp->content;
  $self->{_hash} = XMLin($self->{eeml},
                         KeyAttr => [qw/id/],
                         ForceArray => [qw/data/]);
  return $self;
}


sub title {
  $_[0]->{_hash}->{environment}->{title};
}


sub description {
  $_[0]->{_hash}->{environment}->{description};
}


sub feed_id {
  $_[0]->{_hash}->{environment}->{id};
}


sub status {
  $_[0]->{_hash}->{environment}->{status};
}


sub feed_url {
  $_[0]->{_hash}->{environment}->{feed};
}


sub creator {
  $_[0]->{_hash}->{environment}->{creator};
}


sub location {
  defined $_[1] ? $_[0]->{_hash}->{environment}->{location}->{$_[1]} :
    $_[0]->{_hash}->{environment}->{location};
}


sub number_of_streams {
  scalar keys %{$_[0]->{_hash}->{environment}->{data}}
}


sub data_value {
  $_[0]->{_hash}->{environment}->{data}->{$_[1]||0}->{value}->{content};
}


sub data_min {
  $_[0]->{_hash}->{environment}->{data}->{$_[1]||0}->{value}->{minValue};
}


sub data_max {
  $_[0]->{_hash}->{environment}->{data}->{$_[1]||0}->{value}->{maxValue};
}


sub data_tags {
  my $tags = $_[0]->{_hash}->{environment}->{data}->{$_[1]||0}->{tag} or return;
  ref $tags ? @$tags : $tags
}


sub update {
  my ($self) = shift;
  my %p = @_;
  my $pachube = $self->pachube;
  my $url = $pachube->url.'/'.$self->id;
  my $data = ref $p{data} ? $p{data} : [$p{data}];
  $pachube->_request(method => 'PUT', url => $url.'.csv',
                     content => (join ',', @$data));
}


sub delete {
  my $self = shift;
  my $pachube = $self->pachube;
  my $url = $pachube->url.'/'.$self->id;
  delete $self->{eeml};
  $pachube->_request(method => 'DELETE', url => $url);
}

1;


=pod

=head1 NAME

Net::Pachube::Feed - Perl extension for manipulating pachube.com feeds

=head1 VERSION

version 1.102900

=head1 SYNOPSIS

  # normally instantiated using:

  use Net::Pachube;
  my $pachube = Net::Pachube->new();
  my $feed = $pachube->feed($feed_id);
  print $feed->title, " ", $feed->status, "\n";
  foreach my $i (0..$feed->number_of_streams-1) {
    print "Stream ", $i, " value: ", $feed->data_value($i), "\n";
    foreach my $tag ($feed->data_tags($i)) {
      print "  Tag: ", $tag, "\n";
    }
  }

  # update several streams at once
  $feed->update(data => [0,1,2,3,4]);

  # update one stream
  $feed->update(data => 99);

=head1 DESCRIPTION

This module encapsulates a www.pachube.com feed.

=head1 METHODS

=head2 C<new( %parameters )>

The constructor creates a new L<Net:Pachube::Feed> object.  This
method is generally only called by the L<Net::Pachube> request
methods.  The constructor takes a parameter hash as arguments.  Valid
parameters in the hash are:

=over

=item id

  The id of the feed.

=item pachube

  The L<Net::Pachube> connection object.

=back

=head2 C<get( )>

This method refreshes the contents of the feed by sending a C<GET>
request to the server.  It is automatically called when the feed
is created but may be called again to refresh the feed data.

=head2 C<eeml( )>

This method returns the L<EEML> of the feed.

=head2 C<title( )>

This method returns the title of the feed from the L<EEML> if the
request was successful.

=head2 C<description( )>

This method returns the description of the feed from the L<EEML> if the
request was successful.

=head2 C<feed_id( )>

This method returns the id of the feed from the L<EEML> if the request
was successful.  It should always be equal to C<< $self->id >> which is
used to request the feed data.

=head2 C<status( )>

This method returns the status of the feed from the L<EEML> if the request
was successful.

=head2 C<feed_url( )>

This method returns the URL for the feed from the L<EEML> if the
request was successful.

=head2 C<creator( )>

This method returns the creator value from the L<EEML> if the request
was successful.

=head2 C<location( [ $key ] )>

This method returns the location information from the L<EEML> if the
request was successful.  If the optional C<key> parameter is not
supplied then a hash reference will be returned.  If the optional
C<key> parameter is supplied then the value for that key from the hash
is returned.

=head2 C<number_of_streams( )>

This method returns the number of data streams present in the feed.

=head2 C<data_value( [ $index ] )>

This method returns the value from the data stream from the L<EEML>
if the request was successful.  If the optional zero-based C<index>
parameter is not provided, it is assumed to be zero.

=head2 C<data_min( [ $index ] )>

This method returns the minimum value for the data stream from the
L<EEML> if the request was successful.  It may be undefined.  If the
optional zero-based C<index> parameter is not provided, it is assumed
to be zero.

=head2 C<data_max( [ $index ] )>

This method returns the maximum value for the data stream from the
L<EEML> if the request was successful.  It may be undefined.  If the
optional zero-based C<index> parameter is not provided, it is assumed
to be zero.

=head2 C<data_tags( [ $index ] )>

This method returns the tag value for the data stream from the L<EEML>
if the request was successful.  It may be undefined or a list of tags.
If the optional zero-based C<index> parameter is not provided, it is
assumed to be zero.

=head2 C<<update( data => \@data_values )>>

This method performs a C<PUT> request in order to update a feed.
It returns true on success or undef otherwise.

=head2 C<delete( )>

This method sends a C<DELETE> request to the server to remove
it from the server.  It returns true if successful or undef
otherwise.

=head1 SEE ALSO

Pachube web site: http://www.pachube.com/

=head1 AUTHOR

Mark Hindess <soft-pachube@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

