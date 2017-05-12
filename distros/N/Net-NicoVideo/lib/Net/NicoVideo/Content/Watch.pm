package Net::NicoVideo::Content::Watch;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);
use Carp qw(croak);

use vars qw(@Members);
@Members = qw(
decoded_content
);

__PACKAGE__->mk_accessors(@Members);

sub members { # implement
    my @copy = @Members;
    @copy;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    # TODO - temporary return
    $self->decoded_content( $self->_decoded_content );

    # status
    if( $self->_decoded_content =~ m{\bhttps://secure.nicovideo.jp/secure/logout\b} ){
        # when user is logging in, "watch" page produces full contents
        $self->set_status_success;
    }else{
        # or user does not logged in, showing brief contents
        $self->set_status_error;
    }

    return $self;
}


1;
__END__
