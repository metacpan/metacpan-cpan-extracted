package Net::NicoVideo::Content::Video;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);

use vars qw(@Members);
@Members = qw(
content_ref
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
    $self->content_ref( $self->_decoded_content );
 
    # status TODO - the judgement is detected by response header
    if( $self ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }

   return $self;
}


1;
__END__
