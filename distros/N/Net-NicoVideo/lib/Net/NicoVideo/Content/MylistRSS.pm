package Net::NicoVideo::Content::MylistRSS;

use strict;
use warnings;
use utf8;
use vars qw($VERSION);
$VERSION = '0.28';

# NOTE: Never inherit with classes that have "get()" or "set()", like Class::Accessor::Fast,
# because these interfere with _component which is decorated with Net::NicoVideo::Decorator, like XML::FeedPP.
use base qw(Net::NicoVideo::Content Net::NicoVideo::Decorator);
use XML::FeedPP;

sub members { # implement
    ();
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );
    $self->_component( XML::FeedPP->new($self->_decoded_content) );
    
    # status
    if( ref($self->_component) and $self->_component->isa('XML::FeedPP') ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }

    return $self;    
}

sub is_closed {
    my $self = shift;
    if( $self->title eq 'マイリスト‐ニコニコ動画'
    and $self->link eq 'http://www.nicovideo.jp/'
    and $self->description eq 'このマイリストは非公開に設定されています。'
    ){
        return 1;
    }
    return 0;
}


1;
__END__
