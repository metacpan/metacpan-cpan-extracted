package Pikeo::API::Album;

use strict;
use warnings;

use base qw( Pikeo::API::Base );

use Carp;
use Data::Dumper;
use Pikeo::API::User;

sub _info_fields {qw( id owner_id owner_username title
                      description cover_url  )}

=head1 NAME

Pikeo::API::Album - Abstraction of a pikeo photo album 

=head1 SYNOPSIS

    use Pikeo::API;
    use Pikeo::API::User;
    use Pikeo::API::Album;

    # create an API object to maintain you session
    # trough out the diferent calls
    my $api = Pikeo::API->new({api_secret=>'asd', api_key=>'asdas'});
    
    # Get a user by id...
    my $user = Pikeo::API::User->new({ api => $api, id=>1 });
    # get the albums for this user
    my $albums = $user->getAlbumsList;
    # get one album photos
    my $album = $albums->[0];
    my $photos = $album->getPhotos();

    # .. or get a album by id 
    my $other_album = Pikeo::API::Album->new({ api => $api, id=>999 });

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::User object.

Required args are:

=over 4

=item * api

Pikeo::API object

Optional args are:

=item * from_xml

XML::LibXML node containing the album details 

=item * id 

id of the album

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    my $self = $class->SUPER::new($params);

    if ( $params->{from_xml} ) {
	  $self->_init_from_xml( $params->{from_xml} );
      return $self;
    }
    if ( $params->{id} ) {
      $self->{id} = $params->{id};
      return $self;
    }
    croak "Need an xml object";
}

=back

=head2 INSTANCE METHODS

=head3 owner()

Pikeo::API::User that owns the album

=cut

sub owner {
    my $self = shift;
    return Pikeo::API::User->new({ id => $self->owner_id, api => $self->api });
}

=head3 id()

Returns the album id

=cut

sub id { return shift->{id} }

=head3 getPhotos()

Return a list of Pikeo::API::Photo with all the photos in the album

=cut
sub getPhotos {
  my $self   = shift;
  my $params = shift;

  my $req_params = { album_id => $self->id };

  if ( $params->{'num_items'} ) {
    $req_params->{'num_items'} = $params->{'num_items'};
  }

  my $doc = $self->api->request_parsed( 'pikeo.albums.getPhotos', $req_params );

  return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}

sub _init_from_xml {
    my $self = shift;
    my $doc  = shift;
    my $nodes = $doc->findnodes("./*");
    for ($nodes->get_nodelist()) {
       $self->{$_->nodeName} = ( $_->to_literal eq 'null' ? undef :  $_->to_literal );
    }
    croak "could not init from XML, missing id" unless $self->{id};
    $self->{_init} = 1;
}

1;
