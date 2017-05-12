package Net::NicoVideo::Content::ThumbInfo;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);
use XML::TreePP;

use vars qw(@Members);
@Members = qw(
video_id
title
description
thumbnail_url
first_retrieve
length
movie_type
size_high
size_low
view_counter
comment_num
mylist_counter
last_res_body
watch_url
thumb_type
embeddable
no_live_play
tags
user_id
);

__PACKAGE__->mk_accessors(@Members);


# DEPRECATED
sub is_failure {
    $_[0]->is_error;
}

sub members { # implement
    my @copy = @Members;
    @copy;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    my $tpp = XML::TreePP->new( force_array => 'tags' )
              ->parse($self->_decoded_content);

    my $params = $tpp->{nicovideo_thumb_response} || {};
    my $thumb  = $params->{thumb} || {};

    for my $name ( ($self->members) ){
        $self->$name( $thumb->{$name} )
            if( $self->can($name) );
    }

    # status
    my $status = $params->{'-status'} || '';
    if( lc($status) eq 'ok' ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }
    
    return $self;
}


1;
__END__
