package Pikeo::API::User;

use strict;
use warnings;

use base qw( Pikeo::API::Base );

use Carp;
use Data::Dumper;
use Pikeo::API::Album;

=head1 NAME

Pikeo::API::User - Abstraction of a pikeo user/person

=cut

sub _info_fields { qw( username profile_url avatar_url location ) }

=head1 SYNOPSIS

    use Pikeo::API;
    use Pikeo::API::User;

    # create an API object to maintain you session
    # trough out the diferent calls
    my $api = Pikeo::API->new({api_secret=>'asd', api_key=>'asdas'});
    
    # Get a user by id...
    my $user1 = Pikeo::API::User->new({ api => $api, id=>1 });

    # .. or get a user by username
    my $user2 = Pikeo::API::User->new({ api => $api, username=>'foo' });

    #get the public photos
    my $photos = $user2->getPublicPhotos();

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::User object.

Required args are:

=over 4

=item * api

Pikeo::API object

=item * username or id

Id or username of the user.

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    my $self = $class->SUPER::new($params);

    if ( $params->{id} ) {
        $self->{id}    = $params->{id};
        $self->{_init} = 0;
        return $self;
    }
    elsif ($params->{username}){
        my $doc = $self->api->request_parsed('pikeo.people.findByUsername', 
                                             { username => $params->{username} }
                                            );
        $self->{id}  = $doc->findvalue("//value") || croak "unkown user";
        $self->{_init} = 0;
        return $self;

    }

    croak "Need an id or a username";
}

=back 

=head2 INSTANCE METHODS

=head3 getPublicPhotos(\%args)

Return a list of Pikeo::API::Photo owned by the user
and marked as public.

=cut 

sub getPublicPhotos {
    my $self   = shift;
    my $params = shift;

    my $req_params = {
        user_id => $self->id,
    };
    if ( $params->{'num_items'} ) {
        $req_params->{'num_items'} = $params->{'num_items'};
    }

    my $doc = $self->api->request_parsed( 'pikeo.people.getPublicPhotos', $req_params );

    return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}

=head3 getContactsPublicPhotos(\%args)

Return a list of Pikeo::API::Photo owned by contacts 
of the user and marked as public

=cut 

sub getContactsPublicPhotos {
    my $self   = shift;
    my $params = shift;

    my $req_params = {
        user_id => $self->id,
    };
    if ( $params->{'num_items'} ) {
        $req_params->{'num_items'} = $params->{'num_items'};
    }

    my $doc = $self->api->request_parsed( 'pikeo.photos.getContactsPublicPhotos', $req_params );

    return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}


=head3 getUserPhotos(\%args)

Return a list of Pikeo::API::Photo containing all the 
photos of the user.

=cut 
sub getUserPhotos {
    my $self   = shift;
    my $params = shift;

    my $req_params = {
        user_id => $self->id,
    };
    if ( $params->{'num_items'} ) {
        $req_params->{'num_items'} = $params->{'num_items'};
    }

    my $doc = $self->api->request_parsed( 'pikeo.photos.getUserPhotos', $req_params );

    return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}

=head3 getAlbumsList()

Return a list of Pikeo::API::Album owned by the user 

=cut 
sub getAlbumsList {
  my $self   = shift;
  my $params = {};

  my $albums = $self->api->request_parsed( 'pikeo.people.getInfo', 
                                           {
                                            'user_id'  => $self->id,
                                           } );

  my @a = ();
  for my $album_xml ( @{$albums->findnodes("//album")} ) {
    push @a, Pikeo::API::Album->new({ api=>$self->api,
                                      from_xml => $album_xml });
  }
  return \@a;

}

=head3 username()

Returns the user username

=head3 profile_url()

Returns the user profile url

=head3 avatar_url()

Returns the user avatar url

=head3 location()

Returns the user location 

=head3 id()

Returns the user id

=cut
 
sub id { return shift->{id} }

sub _init {
    my $self = shift;
    my $doc  = $self->api->request_parsed( 'pikeo.people.getInfo', {
                                           'user_id'  => $self->id,
                                          } );
    $self->_init_from_xml( [$doc->findnodes("response/person/*")] );
    $self->{_init}  = 1;
    $self->{_dirty} = 0;
}

sub _init_from_xml {
    my $self = shift;
    my $nodes  = shift;
    for ( @$nodes ) {
       $self->{$_->nodeName} = ( $_->to_literal eq 'null' ? undef :  $_->to_literal );
    }
}

1;
