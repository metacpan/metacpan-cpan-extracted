package Net::NicoVideo::Response::Video;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw/Net::NicoVideo::Response/;
use Net::NicoVideo::Content::Video;

sub parsed_content { # implement
    my $self = shift;

    my $parsed_content = Net::NicoVideo::Content::Video->new($self->_component)->parse;
    if( $self->header("X-Died") or $self->header("Client-Aborted") ){
        $parsed_content->set_status_error;
    }else{
        $parsed_content->set_status_success;
    }
    return $parsed_content;
}


1;
__END__
