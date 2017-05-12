package Pikeo::API::Photo;

use strict;
use warnings;

use base qw( Pikeo::API::Base );

use Pikeo::API::Comment;
use Pikeo::API::User;

use Carp;
use Data::Dumper;

=head1 NAME

Pikeo::API::Photo - Abstraction of a pikeo photo 

=cut


sub _info_fields { qw( title is_family is_contact is_friend owner_username
                       original_file_size original width secret url_prefix 
                       description height mime_type date_posted date_taken 
                       owner_id title tags
                      ) }

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::Contact object.

Required args are:

=over 4

=item * api

Pikeo::API object

=item * from_xml

XML::LibXML node containing the contacts definitions

=back

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
    croak "Need an id";
}

=head3 id()

Photo id

=cut 
sub id { return shift->{id} }

=head3 comments()

List of Pikeo::API::Comment objects representing the photo comments.

=cut
sub comments {
    my $self = shift;
    my $doc  = $self->api->request_parsed( 'pikeo.comments.getList', {
                                            photo_id  => $self->{id},
                                          } );
    my $nodes = $doc->findnodes("response/value/array/comment");
    my @comments = ();
    for my $c ($nodes->get_nodelist()) {
        next unless $c;
        push @comments, Pikeo::API::Comment->new({
                api      => $self->api,
                from_xml => $c,
        });
    }
    return \@comments;
}

=head3 setPrivacy(\%args)

Change the privacy level of the photo.

Required args:

=over 4

=item * access_type 

The "access_type" is chosen from :

  0 for private
  2 for friends only
  4 for family only
  6 for friends and family only
  7 for publicAuthentication is required.

=back

Optional args:

=over 4

=item * force_quit_group

force_quit_group allow you to decide if photos can quit groups automatically.

It happens when photo privacy change to a more private level that does not correspond to group accessibility. 

=back 

=cut 

sub setPrivacy {
    my $self   = shift;
    my $params = shift;

    croak "missing param 'access_type'" 
        unless $params->{access_type};

    my $req_params = {
        photo_id_list => "[".$self->id."]",
        access_type   => $params->{access_type},
    };

    if ( $params->{force_quit_group} ) {
        $req_params->{force_quit_group} = ( $params->{force_quit_group} ? 1 : 0 );
    }

    $self->api->request_parsed( 'pikeo.photos.setPrivacy', $req_params );

    return 1;
}

=head3 addComment(\%args)

Adds a comment to the photo

Required args:

=over 4

=item * text 

The text of the comment

=back

Optional args:

=over 4

=item * in_reply_to

Pikeo::API::Comment parent comment

=item * parent_id

id of the parent comment

=back 

=cut 
sub addComment {
    my $self   = shift;
    my $params = shift;

    croak "missing param 'text'" 
        unless $params->{text};
    
    my $req_params = {
                        photo_id => $self->id,
                        text     => $params->{text},
                     };

    if ( $params->{in_reply_to} ) {
        croak "invalid param type 'in_reply_to'"
          unless ref( $params->{in_reply_to} ) eq 'Pikeo::API::Comment';
        $req_params->{parent_id} = $params->{in_reply_to}->id;
    }
    if ( $params->{parent_id} ) {
        $req_params->{parent_id} = $params->{parent_id};
    }

    my $d = $self->api->request_parsed( 'pikeo.comments.addComment', $req_params );
    return $d->findvalue("//value");
    
}

=head3 owner()

Pikeo::API::User that owns the photo

=cut

sub owner {
    my $self = shift;
    return Pikeo::API::User->new({ id => $self->owner_id, api => $self->api });
}

=head3 thumbnail_url($size)

Returns the url for the photo thumbnail of the given size.

Size can be one of the following:

1016x762
500x400
200x150
96x72
75x75
50x50

=cut

sub thumbnail_url {
    #urlPrefix/thumb/secret/thumbnail.jpg
    my $self = shift;
    my $size = shift;

    $self->_init unless $self->_init_done();

    return $self->url_prefix."thumb/".$self->secret.$size.".jpg";

}

=head3 original_url()

Return full url to the original photo file

=cut
sub original_url {
    my $self = shift;
    $self->_init unless $self->_init_done();

    return $self->url_prefix."upload/".$self->original;
}

sub _init {
    my $self = shift;
    my $doc  = $self->api->request_parsed( 'pikeo.photos.getInfo', {
                                           'photo_id'  => $self->{id},
                                          } );
    $self->_init_from_xml( $doc );
    $self->{_init}  = 1;
    $self->{_dirty} = 0;
}

sub _init_from_xml {
    my $self = shift;
    my $doc  = shift;
    my $nodes = $doc->findnodes("response/photo/*");
    for ($nodes->get_nodelist()) {
       next if $_->nodeName eq 'value';
       $self->{$_->nodeName} = ( $_->to_literal eq 'null' ? undef :  $_->to_literal );
    }

    my @parsed_tags = ();
    my $tags = $doc->findnodes("//tag");
    for my $tag ($tags->get_nodelist()) {
       push @parsed_tags, {
                            id => $tag->findvalue("./id"),
                            category => $tag->findvalue("./category"),
                            name => $tag->findvalue("./name"),
                          }; 
    }
    $self->{tags} = \@parsed_tags;

}
=head3 title() 

=head4 is_family() 

=head4 is_contact() 

=head4 is_friend() 

=head4 owner_username()
                       
=head3 original_file_size() 

=head3 original() 

=head3 secret() 

=head3 url_prefix() 

=head3 description() 

=head3 height() 

=head3 width() 

=head3 mime_type() 

=head3 date_posted() 

=head3 date_taken()

=head3 owner_id() 

=head3 title()

=head3 tags()

=cut
1;
