# $Id: P50.pm 115 2006-04-10 23:41:37Z fil $
package t::P50;
use strict;

sub DEBUG () { 0 }

sub new
{
    my( $package, %args ) = @_;
    DEBUG and warn "new";
    return bless { %args }, $package;
}

sub buildthing
{
    my( $self, %args ) = @_;

    return Duffus->new( %args );
}


################################################################
package Duffus;

use strict;

sub new
{
    my $package = shift;
    return bless { @_ }, $package;
}

sub number
{
    my( $self ) = @_;
    return $self->{number};
}


1;
