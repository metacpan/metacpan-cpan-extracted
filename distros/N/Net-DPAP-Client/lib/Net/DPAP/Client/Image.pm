package Net::DPAP::Client::Image;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp::Assert;
use Net::DAAP::DMAP qw(:all);

__PACKAGE__->mk_accessors(qw(ua kind id name aspectratio creationdate
imagefilename thumbnail_url hires_url));

sub thumbnail {
  my $self = shift;

  my $ua = $self->ua;
  my $url = $self->thumbnail_url;

  return $self->_decode($ua->get($url)->content);
}

sub hires {
  my $self = shift;

  my $ua = $self->ua;
  my $url = $self->hires_url;

  return $self->_decode($ua->get($url)->content);
}

sub _decode {
  my $self = shift;
  my $data  = shift;
  my $dmap = dmap_unpack($data);

  assert($dmap->[0]->[0] eq 'daap.databasesongs');
  foreach my $tuple (@{$dmap->[0]->[1]}) {
    my $key = $tuple->[0];
    my $value = $tuple->[1];
    assert($value == 200) if $key eq 'dmap.status';
    next unless $key eq 'dmap.listing';
    my $list = $value->[0]->[1];

    foreach my $subtuple (@$list) {
      my $subsubkey = $subtuple->[0];
      my $subsubvalue = $subtuple->[1];
      return $subsubvalue if $subsubkey eq 'dpap.picturedata';
    }
  }
}

1;

__END__

=head1 NAME

Net::DPAP::Client::Image - Remote DPAP image

=head1 DESCRIPTION

This module represents a remote iPhoto shared image.

=head1 METHODS

=head2 aspectratio

This returns the aspect ratio of the image.

=head2 creationdate

This returns the creation date of the image as a UNIX timestamp. 

=head2 id 

This returns the internal iPhoto ID for the image. You probably don't
need to worry about this.

=head2 imagefilename

This returns the filename of the image.

=head2 kind

This returns the kind of file of the image. Currently an
incomprehensible number.

=head2 name

This returns the name of the image.

=head2 thumbnail_url

This returns the URL of the image thumbnail.

=head2 thumbnail 

This returns the thumbnail binary.

=head2 hires_url

This returns the URL of the image hires.

=head2 hires

This returns the hires binary.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004-6, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
