#!/usr/bin/perl -swI..
##
## PList.pm -- A Persistent List Object Example. 
##
## $Date: 1998/12/17 19:29:41 $
## $Revision: 0.10 $
## $State: Exp $
## $Author: root $
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

package Plist; 
use Persistence::Object::Simple; 

@ISA = ( "Persistence::Object::Simple" ); 
 
sub new { 

	my ( $class, %args ) = @_; 

	my $self = SUPER::new ( $class, __Dope => "/tmp" ); 
	$self->{ idata } = (); 

	return $self 

}


sub element { 

	my ( $self, $element, $value ) = @_; 

	value $self->{ idata }->[ $element ] = $value if $value; 
	return $self->{ idata }->[ $element ]; 

}

'True Value.'

__END__


