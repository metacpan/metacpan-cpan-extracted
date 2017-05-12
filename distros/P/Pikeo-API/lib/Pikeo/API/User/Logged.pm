package Pikeo::API::User::Logged;

use strict;
use warnings;
use Carp;
use MIME::Base64;
use Pikeo::API::Photo;
use Pikeo::API::Contact;

use base qw( Pikeo::API::User );

sub _info_fields { qw( real_name location avatar_url username email
                       profile_url birthday blog_url 
                     ) }

=head1 NAME

Pikeo::API::User::Logged - Abstraction the logged in pikeo user

=head1 DESCRIPTION

This modules provides an interface to the logged in user in pikeo.

This module inherits from Pikeo::API::User so all the methods of 
Pikeo::API::User are also available.

=head1 SYNOPSIS

    use Pikeo::API;
    use Pikeo::API::User::Logged;

    # create an API object to maintain you session
    # trough out the diferent calls
    my $api = Pikeo::API->new({api_secret=>'asd', api_key=>'asdas'});
    $api->login({ username => 'a', password => 'b' });
    
    # Get the logged in user 
    my $user1 = Pikeo::API::User::Logged->new({ api => $api });

    #get the public photos
    my $photos = $user->getPublicPhotos();


=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::User object.

Required args are:

=over 4

=item * api

Pikeo::API object

=cut


sub new {
   my $class = shift;
   my $params= shift;

   croak "need an api" unless $params->{api};

   croak "you must be logged in" unless $params->{api}->is_logged_in();

   my $self = bless { _init_done => 1, _api => $params->{api} }, $class;

   my $doc = $params->{api}->request_parsed('pikeo.people.getMyInfo',{});
   for ( @{$doc->findnodes('/response/my_person/*')} ) {
      $self->{$_->nodeName} = ( $_->to_literal eq 'null' ? undef :  $_->to_literal );
   }
   
   croak "could not instantiate current user" unless $self->id;

   return $self;
}

=back

=head2 INSTANCE METHODS

=head3 uploadPhoto(\%args)

Upload one photo to the photo repository

Returns the Pikeo::API::Photo object representing the uploaded photo

Required args:

=over 4

=item * picture

One file name containing the picture or a IO::File object pointing to the picture

=back 

Optional args:

=over 4

=item * title

The picture title

=item * access_type

The access type of the picture: 0 for PRIVATE, 2 for FRIEND, 4 for FAMILY, 6 for FRIEND AND FAMILY and 7 for PUBLIC. By default the picture is PUBLIC

=item * title 

Title associated to the photo

=item * description

Description of the photo

=item * 

A list of tags associated to the uploaded photo

The list of tags is a reference to an array containing 'category' => 'tag' pairs. 

Example: [ 'where' => 'lisbon', 'who' => 'donald' , ... ]

Tag categories can be: who, what or where. 

Only letters, figures and spaces are authorized in the tag itself.

=back

=cut

sub uploadPhoto {
    my $self   = shift;
    my $params = shift;

    my $req_params = { 
        title       => $params->{title} || '',
        access_type => (defined($params->{access_type}) ? ($params->{access_type}) : 7),
        description => $params->{description} || '',
    };

    croak "missing required param 'picture'"
        unless $params->{picture};

    # Is this a file path?
    if (ref($params->{picture}) eq '') {
      # let's convert this to an IO::File
      $params->{picture} = IO::File->new($params->{picture}, 'r');  
    }
    elsif ( ref($params->{picture}) ne 'IO::File' ) {
      croak "invalid param format for 'picture'";
    }
    $req_params->{picture} = encode_base64(join('',$params->{picture}->getlines()));

    if ( $params->{'tags'} ) {
        my @tags = ();
        while (scalar(@{$params->{'tags'}})) {
            push @tags, shift(@{$params->{'tags'}}).":".shift(@{$params->{'tags'}});
        }
        $req_params->{tags} = join(",",@tags);
    }

    my $doc = $self->api->request_parsed( 'pikeo.photos.upload', $req_params );
    my $photo_id = $doc->findvalue("//value");
    croak "Failed to upload photo, no photo id returned"
        unless $photo_id;

    return Pikeo::API::Photo->new({ id => $photo_id, api => $self->api });
}


=head3 getMyCommentedPhotos()

Return all the photos that the user owns that are commented.

Return a list of Pikeo::API::Photo

=cut

sub getMyCommentedPhotos {
    my $self   = shift;
    my $params = shift;

    my $req_params = {};
    
    if ( $params->{num_items} ) {
        $req_params->{num_items} = $params->{num_items};
    }

    my $doc = $self->api->request_parsed( 'pikeo.comments.getMyCommentedPhotos', $req_params );

    return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}

=head3 getPicturesCommentedByMe()

Returns all the photos that were commented by the user.

Return a list of Pikeo::API::Photo

=cut

sub getPicturesCommentedByMe {
    my $self   = shift;
    my $params = shift;

    my $req_params = {};
    
    if ( $params->{num_items} ) {
        $req_params->{num_items} = $params->{num_items};
    }

    my $doc = $self->api->request_parsed( 'pikeo.comments.getPicturesCommentedByMe', $req_params );

    return $self->_photos_from_xml({ xml => [$doc->findnodes('//photo')] });
}

=head3 getContactsList()

The function will get the contacts of the logged user.

Returns a list of Pikeo::API::Contact objects.

=cut

sub getContactsList {
    my $self   = shift;
    my $params = shift;

    my $doc = $self->api->request_parsed( 'pikeo.contacts.getList', {} );

    my @contacts = ();
    for my $contact (@{ $doc->findnodes('//contact') }) {
        push @contacts, Pikeo::API::Contact->new({api=>$self->api, from_xml=>$contact});
    } 
    return \@contacts;
}


sub _init { shift->{_init_done} = 1 }

1;
