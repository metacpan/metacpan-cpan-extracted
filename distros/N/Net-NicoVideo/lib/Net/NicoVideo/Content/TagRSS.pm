package Net::NicoVideo::Content::TagRSS;

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

1;
__END__
