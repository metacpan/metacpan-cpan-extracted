package Net::Social::Mapper::Persona::Flickr;

use strict;
use base qw(Net::Social::Mapper::Persona::Generic);
use Feed::Find;
use JSON::Any;
use URI;
use Data::Dumper;

our $FLICKR_API_KEY = 'efe286838b28127e10271d239dec10bf';

=head1 NAME

Net::Social::Mapper::Person::Flickr - the persona for a Flickr account

=head2 SYNOPSIS

See C<Net::Social::Mapper>

=cut

sub _init {
    my $self = shift;

    # Guess at a bunch of stuff
    $self = $self->SUPER::_init;
    
    if ($self->{user} =~ m!^\d+@.+!) {
        $self->{id}   = delete $self->{user};
    } else {
        $self->{id}   = $self->_fetch_nsid($self->{user}) || return $self;
    }
    for my $format (qw(atom rss_200)) {
        push @{$self->{feeds}}, "http://api.flickr.com/services/feeds/photos_public.gne?id=$self->{id}&lang=en-us&format=${format}";        
    }

    # Now try and get the actual values from flickr
    my $info = $self->_fetch_userinfo($self->{id}) || return $self;
    $self->{full_name} = $info->{realname}->{_content};
    $self->{profile}   = $info->{profileurl}->{_content};
    $self->{homepage}  = $info->{photosurl}->{_content};
    ($self->{user})    = ($self->{homepage} =~ m!/([^/]+)/?$!) unless defined $self->{user};
    # See http://www.flickr.com/services/api/misc.buddyicons.html
    if ($info->{iconserver}>0) {
        my $farm = $info->{iconfarm};
        my $serv = $info->{iconserver};
        my $id   = $self->{id};
        $self->{photo}    = "http://farm${farm}.static.flickr.com/${serv}/buddyicons/${id}.jpg" 
    }
            

    return $self;
}

sub _fetch_nsid {
    my $self = shift;
    my $user = shift;
    my $info = $self->_do_flickr('flickr.urls.lookupUser', url => "http://flickr.com/photos/${user}/") || return;
    return $info->{user}->{id};
}

sub _fetch_userinfo {
    my $self = shift;
    my $id   = shift;
    my $key  = $self->{_flickr_api_key} || $FLICKR_API_KEY;
    my $info = $self->_do_flickr('flickr.people.getInfo', user_id => $id );
    return $info->{person};
}

sub _do_flickr {
    my $self         = shift;
    my $method       = shift;
    my %params       = @_;
    $params{method}  = $method;
    $params{api_key} = $self->{_flickr_api_key} || $FLICKR_API_KEY;
    $params{format}  = 'json';
    $params{nojsoncallback} = 1;
    
    my $url          = URI->new("http://www.flickr.com/services/rest/");
    $url->query_form(%params);
    my $page = $self->mapper->get("$url") || return;
    return eval { $self->_json->decode($page) };
}

1;

