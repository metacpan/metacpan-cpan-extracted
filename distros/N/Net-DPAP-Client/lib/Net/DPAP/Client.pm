package Net::DPAP::Client;
use strict;
use warnings;
use Carp::Assert;
use Net::DAAP::DMAP qw(:all);
use Net::DPAP::Client::Album;
use Net::DPAP::Client::Image;
use LWP::UserAgent;
use URI;
use base qw(Class::Accessor::Fast);
our $VERSION = '0.26';

__PACKAGE__->mk_accessors(qw(hostname port ua server databases_count
item_name login_required dmap_protocol_version dpap_protocol_version
session_id containers));

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;

  $self->port(8770);

  # Let's look like an iPhoto client
  my $ua = LWP::UserAgent->new(keep_alive => 1);
  $ua->agent('iPhoto/4.01 (Macintosh; PPC)');
  $ua->default_headers->push_header('Client-DMAP-Version', '1.0');
  $ua->default_headers->push_header('Client-DPAP-Version', '1.0');
  $self->ua($ua);

  return $self;
}

sub connect {
  my $self = shift;

  # Get server info
  my $response =  $self->_do_get("server-info");
  $self->server($response->header('DPAP-Server'));
  assert($response->header('Content-Type') eq
    'application/x-dmap-tagged');

  my $dmap = dmap_unpack($response->content);
  assert($dmap->[0]->[0] eq 'dmap.serverinforesponse');
  foreach my $tuple (@{$dmap->[0]->[1]}) {
    my $key = $tuple->[0];
    my $value = $tuple->[1];
    assert($value == 200) if $key eq 'dmap.status';
    $self->item_name($value) if $key eq 'dmap.itemname';
    $self->databases_count($value) if $key eq 'dmap.databasescount';
    $self->login_required($value) if $key eq 'dmap.loginrequired';
    $self->dmap_protocol_version($value) if $key eq 'dmap.protocolversion';
    $self->dpap_protocol_version($value) if $key eq 'dpap.protocolversion';
  }

  # Login (get session id)
  $response = $self->_do_get("login");
  $dmap = dmap_unpack($response->content);

  assert($dmap->[0]->[0] eq 'dmap.loginresponse');
  foreach my $tuple (@{$dmap->[0]->[1]}) {
    my $key = $tuple->[0];
    my $value = $tuple->[1];
    assert($value == 200) if $key eq 'dmap.status';
    $self->session_id($value) if $key eq 'dmap.sessionid';
  }

  # See how many containers there are
  $response = $self->_do_get("databases");
  $dmap = dmap_unpack($response->content);
  assert($dmap->[0]->[0] eq 'daap.serverdatabases');
  foreach my $tuple (@{$dmap->[0]->[1]}) {
    my $key = $tuple->[0];
    my $value = $tuple->[1];
    assert($value == 200) if $key eq 'dmap.status';
    next unless $key eq 'dmap.listing';
    foreach my $subtuple (@{$value->[0]->[1]}) {
      my $subkey = $subtuple->[0];
      my $subvalue = $subtuple->[1];
      $self->containers($subvalue) if $subkey eq 'dmap.containercount';
    }
  }

  # Get album info
  my @albums;
  $response = $self->_do_get("databases/1/containers");
  $dmap = dmap_unpack($response->content);

  assert($dmap->[0]->[0] eq 'daap.databaseplaylists');
  foreach my $tuple (@{$dmap->[0]->[1]}) {
    my $key = $tuple->[0];
    my $value = $tuple->[1];
    assert($value == 200) if $key eq 'dmap.status';
    next unless $key eq 'dmap.listing';
    foreach my $subtuple (@$value) {
      assert($subtuple->[0] eq 'dmap.listingitem');

      my $album = Net::DPAP::Client::Album->new();
      foreach my $subsubtuple (@{$subtuple->[1]}) {
	my $subsubkey = $subsubtuple->[0];
	my $subsubvalue = $subsubtuple->[1];
	next unless $subsubkey =~ s/dmap.item//;
	$album->$subsubkey($subsubvalue);
      }

      # Skip the main library
#      next if $album->name eq 'Photo Library';
      push @albums, $album;
    }
  }

  # Get image info for each album
  foreach my $album (@albums) {
    my $albumid = $album->id;
    my @images;

    $response = $self->_do_get("databases/1/containers/$albumid/items", meta => 'dpap.aspectratio,dpap.imagefilesize,dpap.creationdate', type => 'photo');
    $dmap = dmap_unpack($response->content);

    assert($dmap->[0]->[0] eq 'daap.playlistsongs');

    foreach my $tuple (@{$dmap->[0]->[1]}) {
      my $key = $tuple->[0];
      my $value = $tuple->[1];
      assert($value == 200) if $key eq 'dmap.status';
      next unless $key eq 'dmap.listing';
      foreach my $subtuple (@$value) {
	assert($subtuple->[0] eq 'dmap.listingitem');
	my $image = Net::DPAP::Client::Image->new();

	my $ua = $self->ua;
	$image->ua($ua);

	foreach my $subsubtuple (@{$subtuple->[1]}) {
	  my $subsubkey = $subsubtuple->[0];
	  my $subsubvalue = $subsubtuple->[1];
	  $subsubkey =~ s/^.+\.(item)?//;
	  $image->$subsubkey($subsubvalue);
	}

	my $imageid = $image->id;

	my $thumbnail_url = $self->_construct_uri('databases/1/items', meta => 'dpap.thumb', query => "('dmap.itemid:$imageid')");
	$image->thumbnail_url($thumbnail_url);

	my $hires_url = $self->_construct_uri('databases/1/items', meta => 'dpap.hires', query => "('dmap.itemid:$imageid')");
	$image->hires_url($hires_url);

	push @images, $image;
      }
    }

    $album->images(\@images);
  }

  return @albums;
}

sub _do_get {
  my $self = shift;
  my ($path, @form) = @_;

  my $ua = $self->ua;
  my $uri = $self->_construct_uri($path, @form);

  my $response = $ua->get($uri);
  die "Error when fetching $uri" unless $response->is_success;
  assert($response->header('Content-Type') eq 'application/x-dmap-tagged');
  return $response;
}

# Using URI module for URI parsing & constructing is more hassle than simply
# storing & passing URI components separately
sub _construct_uri {
  my $self = shift;
  my ($path, @form) = @_;
  
  my $host = $self->hostname;
  my $port = $self->port;
 
  my $uri = "http://$host:$port/$path";
 
  my $session_id = $self->session_id;
  if (defined $session_id) {
    unshift @form, 'session-id' => $session_id;
  }
 
  if ($#form > 0) {
    my ($key, $value, @form) = @form;
    $uri .= "?$key=$value";

    while ($#form > 0) {
      ($key, $value, @form) = @form;
      $uri .= "&$key=$value";
    }
  }
  return $uri;
}

1;

__END__

=head1 NAME

Net::DPAP::Client - Connect to iPhoto shares (DPAP)

=head1 SYNOPSIS

  use Net::DPAP::Client;
  my $client = Net::DPAP::Client->new;
  $client->hostname($hostname);
  my @albums = $client->connect;

  foreach my $album (@albums) {
    print $album->name, "\n";
    foreach my $image (@{$album->images}) {
      print "  ", $image->name, "\n";
      my $thumbnail = $image->thumbnail;
      my $hires = $image->hires;
    }
  }

=head1 DESCRIPTION

This module provides a DPAP client. DPAP is the Digital Photo Access
Protocol and is the protocol that Apple iPhoto uses to share photos.
This allows you to browse shared albums, and download thumbnail and
hires versions of shared photos.

It currently doesn't support password-protected shares.

=head1 METHODS

=head2 new

The constructor:

  my $client = Net::DPAP::Client->new;
  $client->hostname($hostname);

=head2 connect

Connect to the hostname:

  my @albums = $client->connect;

=head1 SEE ALSO

Net::DPAP::Client::Album, Net::DPAP::Client::Image.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004-6, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
