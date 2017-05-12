package Pangloss::Apache::Handler;

use strict;
use warnings::register;

use Apache;
use Apache::Constants qw(:response);
use OpenFrame::Response qw( ofOK ofREDIRECT ofDECLINE ofERROR );

use base      qw( Pangloss::WebApp );
use accessors qw( response_seg );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.10 $ '))[2];
our $WEBAPP;

warn( "($$) starting up...\n" ) if warnings::enabled;

#------------------------------------------------------------------------------
# Class methods

sub handler ($$) {
    my $class   = shift;
    my $request = shift;

    $WEBAPP ||= $class->new;

    $WEBAPP->handle_request( $request );
}

#------------------------------------------------------------------------------
# WebApp methods

sub handle_request {
    my $self    = shift;
    my $request = shift;

    # OF::Seg::Apache returns status as the pipeline production
    my $response = $self->SUPER::handle_request( $request );

    return DECLINED if (not defined $response or $response->code == ofDECLINE);
    return OK;
}

# TODO: patch Pipeline::Config to add cleanups feature and remove this
sub init_controller {
    my $self = shift;
    my $controller = $self->SUPER::init_controller(@_);

    use OpenFrame::Segment::Apache::Response;
    $self->response_seg( OpenFrame::Segment::Apache::Response->new );

    return $controller;
}

# TODO: patch Pipeline::Config to add cleanups feature and remove this
sub create_cleanups {
    my $self = shift;
    return [ $self->response_seg ];
}

1;
