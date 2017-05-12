use strict;
use warnings;
package Net::Pachube;
BEGIN {
  $Net::Pachube::VERSION = '1.102900';
}

# ABSTRACT: Perl extension for accessing pachube.com


use 5.006;
use base qw/Class::Accessor::Fast/;
use Carp;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Net::Pachube::Feed;

__PACKAGE__->mk_accessors(qw/key url user_agent/);
__PACKAGE__->mk_ro_accessors(qw/http_response/);


sub new {
  my $pkg = shift;
  $pkg->SUPER::new({ url => 'http://www.pachube.com/api',
                   user_agent => LWP::UserAgent->new(),
                   key => $ENV{PACHUBE_API_KEY},
                   @_ });
}


sub feed {
  my ($self, $feed_id, $fetch) = @_;
  $fetch = 1 unless (defined $fetch);
  Net::Pachube::Feed->new(id => $feed_id, pachube => $self, fetch => $fetch);
}


sub create {
  my $self = shift;
  my %p = @_;
  exists $p{title} or croak "New feed should have a 'title' attribute.\n";
  my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd" version="5">
};
  my %args =
    (
     title => [ $p{title} ],
    );
  foreach (qw/description icon website email/) {
    $args{$_} = [$p{$_}] if (exists $p{$_});
  }
  my %location = ();
  foreach (qw/exposure domain disposition/) {
    $location{$_} = $p{$_} if (exists $p{$_});
  }
  foreach (qw/lat lon ele/) {
    $location{$_} = [$p{$_}] if (exists $p{$_});
  }
  $location{name} = [$p{location_name}] if (exists $p{location_name});
  $args{location} = \%location if (scalar keys %location);
  $xml .= XMLout(\%args, RootName => "environment");
  $xml .= "</eeml>\n";
  my $resp = $self->_request(method => 'POST', url => $self->url.'.xml',
                             content => $xml) or return;
  my $url = $resp->header('Location') or return;
  return unless ($url =~ m!/(\d+)\.xml$!);
  $self->feed($1);
}

sub _request {
  my $self = shift;
  my $key = $self->key or
    croak(q{No pachube api key defined.
Set PACHUBE_API_KEY environment variable or pass 'key' parameter to the
constructor.
});
  my %p = @_;
  my $ua = $self->user_agent;
  $ua->default_header('X-PachubeApiKey' => $key);
  my $request = HTTP::Request->new($p{method} => $p{url});
  $request->content($p{content}) if (exists $p{content});
  my $resp = $self->{http_response} = $ua->request($request);
  $resp->is_success && $resp;
}

1;


=pod

=head1 NAME

Net::Pachube - Perl extension for accessing pachube.com

=head1 VERSION

version 1.102900

=head1 SYNOPSIS

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

This module provides a simple API to fetch and/or update pachube.com
feeds.

=head1 ATTRIBUTES

=head2 C<key( [$new_key] )>

This method is an accessor/setter for the C<key> attribute which is
the Pachube API key to use.

=head2 C<url( [$new_url] )>

This method is an accessor/setter for the C<url> attribute
which is the base URL to use for all HTTP requests.

=head2 C<user_agent( [$new_user_agent] )>

This method is an accessor/setter for the C<user_agent> attribute
which is the L<LWP> user agent object to use for all HTTP requests.

=head1 METHODS

=head2 C<new( %parameters )>

The constructor creates a new L<Net:Pachube> object.  The constructor
takes a parameter hash as arguments.  Valid parameters in the hash
are:

=over

=item key

  The Pachube API key to use.  This parameter is optional.  If it is
  not provided then the value of the environment variable
  C<PACHUBE_API_KEY> is used.

=item url

  The base URL to use for all HTTP requests.  The default is
  C<http://www.pachube.com/api>.

=item user_agent

  The L<LWP> user agent object to use for all HTTP requests.  The
  default is to create a new one for each new L<Net::Pachube> object.

=back

=head2 C<feed( $feed_id )>

This method constructs a new L<Net::Pachube::Feed> object and retrieves
the feed data from the server.

=head2 C<create( %parameters )>

This method makes a C<POST> request to create a new feed.  If
successful, it returns a L<Net::Pachube::Feed> object for the new feed
otherwise it returns undef.  The following keys are significant in the
hash passed to this method:

=over

=item title

  The title of the new feed.  This is the only mandatory attribute.

=item description

  A description of the new feed.

=item icon

  The URL of an icon to associate with the new feed.

=item website

  The URL of a website to associate with the new feed.

=item email

  An email to associate with the new feed.  B<This email address will
  be publicly available on the L<www.pachube.com> site, so please
  don't use any email address you wish to keep private.>

=item exposure

  The 'exposure' of the new feed - either 'outdoor' or 'indoor'.

=item disposition

  The 'disposition' of the new feed - either 'fixed' or 'mobile'.

=item domain

  The 'domain' of the new feed - either 'physical' or 'virtual'.

=item location_name

  The name of the location of the new feed.

=item lat

  The latitude of the new feed.

=item lon

  The longitude of the new feed.

=item ele

  The elevation of the new feed.

=back

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

