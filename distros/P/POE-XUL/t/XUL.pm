# $Id: XUL.pm 509 2007-09-12 07:20:01Z fil $
package t::XUL;

use strict;
use warnings;

use base 'POE::Component::XUL';

###############################################################
sub build_http_server
{
    my( $self, $addr, $port ) = @_;
    $self->{mimetypes} = MIME::Types->new();
}

sub log_setup
{
    my( $self ) = @_;
    delete $self->{logging}{stderr_fh};
    $self->SUPER::log_setup;
    $self->{logging}{stderr_fh} = $self->{logging}{log_fh};
}

1;
