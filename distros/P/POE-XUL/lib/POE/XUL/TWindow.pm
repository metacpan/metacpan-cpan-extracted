package POE::XUL::TWindow;
# $Id$
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;
use Carp;

use POE::XUL::Node;
use Scalar::Util qw( blessed );

use constant DEBUG => 0;

our $VERSION = '0.0601';

##############################################################
sub is_window { 1 }

##############################################################
sub new
{
    my( $package, %atts ) = @_;
    my $self = bless {  attributes => { %atts },
                        events     => {} 
                     }, $package;
    return $self;
}

##############################################################
*tag = sub { 'twindow' };
*id = _mk_accessor( 'id' );
*width = _mk_accessor( 'width' );
*height = _mk_accessor( 'height' );
*status = _mk_accessor( 'status' );
*menubar = _mk_accessor( 'menubar' );
*toolbar = _mk_accessor( 'toolbar' );
*scollbars = _mk_accessor( 'scrollbars' );

sub _mk_accessor
{
    my( $tag ) = @_;
    return sub {
        my( $self, $value ) = @_;
        if( @_ == 2 ) {
            return $self->{attributes}{$tag} = $value;
        }
        else {
            return $self->{attributes}{$tag};
        }
    }
}

##############################################################
sub attach
{
    my( $self, $name, $what ) = @_;
    POE::XUL::Node::attach( $self, $name, $what );
}
*addEventListener = \&attach;

sub detach
{
	my ($self, $name) = @_;
    POE::XUL::Node::detach( $self, $name );
}	
*removeEventListener = \&detach;

sub event 
{
	my ($self, $name) = @_;
    POE::XUL::Node::event( $self, $name );
}

##############################################################
sub dispose
{
    my( $self ) = @_;
    # events might cause cyclic references
    $self->{events} = {};
    return;
}

##############################################################
## Create the final Window object
sub create_window
{
    my( $self ) = @_;
    my $id = $self->id;
    my $window = POE::XUL::Window->new( %{ $self->{attributes} }, 
                                       tag => 'window', id => $id, name => $id 
                                     );

    while( my( $name, $what ) = each %{ $self->{events} } ) {
        $window->attach( $name, $what );
    }
    return $window;
}
