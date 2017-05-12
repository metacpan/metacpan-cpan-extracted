package Pikeo::API::Photos;

use strict;
use warnings;
use base qw( Pikeo::API::Base );
use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Pikeo::API::Photo;

=head1 NAME

Pikeo::API::Photos

=head1 SYNOPSIS

    use Pikeo::API;
    use Pikeo::API::Photos;

    # create an API object to maintain you session
    # trough out the diferent calls
    my $api = Pikeo::API->new({secret=>'asd', key=>'asdas'});
    
    # Create the Photos facade
    my $photos = Pikeo::API::Photos->new({ api => $api });

    # Search for photos
    $photos_searched = $photos->search({ text=>'shozu', num_items=>5 });

=head1 DESCRIPTION

This modules provides an interface to the pikeo API photos searching methods.

The methods normally return a list of Pikeo::API::Photo objects.

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::Photos object.

Required args are:

=over 4

=item * api

The Pikeo::API object used to interact with the pikeo API

=back

=head2 INSTANCE METHODS

=head3 getMostViewed(\%args)

(pikeo.photos.getMostViewed)

Gets most viewed public photos from the whole photo repository.

Returns a list of Pikeo::API::Photo objects

Optional args:

=over 4

=item * num_items

Maximum number of items to return. Default 100, maximum 500.

=back

=cut 

sub getMostViewed {
  my $self   = shift;
  my $params = shift;

  my $req_params = {};

  if ( $params->{'num_items'} ) {
    $req_params->{'num_items'} = $params->{'num_items'};
  }

  my $doc = $self->api->request_parsed( 'pikeo.photos.getMostViewed', $req_params );

  return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}


=head3 search(\%args)

(pikeo.photos.search)

Search photos which title or associated tags contains a given text, or that match with all different criteria sent in parameters.

Returns a list of Pikeo::API::Photo objects

Optional args:

=over 4

=item * num_items

Maximum number of items to return. Default 100, maximum 500.

=item * text

The text to search in photo title or tag name, must contain at least 3 characters

=item * offset

Number of the first element to return.

=item * user_id

Select photos for this user Id

=item * user

Select photos for this user

=item * album_id

Select photos for this album Id

=item * album

Select photos for this album

=item * group_id

Select photos for this group id

=item * include_contact_photos

Boolean, Include photos from contacts too

=item * only_public

Boolean, Filter to public photos only

=item * order_asc

Boolean, Acsendant or descendant order

=item * order_type

Order Type : 
    0 by default, 
    1 by date taken,
    2 by upload date, 
    3 by most viewed,
    4 by comment date, 
    5 by group add date.

=item * tag_id_list

Reference to an array

Select photos for this list of tag id 

=item * high_date
=item * end_date

Select photos which date is before this date

Date format: 2008-01-29 10:00:53

=item * low_date
=item * start_date

Select photos which date is after this date

Date format: 2008-01-29 10:00:53

=back 

=cut

sub search {
  my $self   = shift;
  my $params = shift;

  my $req_params = {};

  for my $p ( qw( text num_items offset user_id album_id group_id 
                  only_public order_type order_asc include_contact_photos ) ) {
    $req_params->{$p} = $params->{$p} if $params->{$p};
  }
  if ( $params->{'user'} ) {
    $req_params->{'user_id'} = $params->{'user'}->id();
  }
  
  $params->{'end_date'} = $params->{'high_date'} if $params->{'high_date'};
  if ( $params->{'end_date'} ) {
    $req_params->{'high_date'} = $params->{'end_date'};
  }
  $params->{'start_date'} = $params->{'low_date'} if $params->{'low_date'};
  if ( $params->{'start_date'} ) {
    $req_params->{'low_date'} = $params->{'start_date'};
  }
  if ( $params->{'album'} ) {
    $req_params->{'album_id'} = $params->{'album'}->id();
  }

  if ( $params->{'tag_id_list'} ) {
    $req_params->{'tag_id_list'} = '[' . join(',',@{$params->{'tag_id_list'}}) . ']';
  }

  my $doc = $self->api->request_parsed( 'pikeo.photos.search', $req_params );

  return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}


1;
