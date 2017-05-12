# perl
#
# Person example class
#
# PQL Perl Query Language
#
# Ralf Peine, Sat Nov 15 11:32:57 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

package Person;

# --- create Instance -----------------
sub new
{
    my $caller  = shift;
    my $class   = ref($caller) || $caller;
    my $self = shift || {};
    
    # let the class go
    bless $self, $class;

    return $self;
}

#--------------------------------------------------------------------------------
#
#  Attributes
#
#--------------------------------------------------------------------------------

# --- ID ---------------------------------------------------------------------

sub set_ID {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{ID} = $value;
}

sub get_ID {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{ID};
}

# --- Prename -------------------------------------------------------------------

sub set_prename {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{prename} = $value;
}

sub get_prename {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{prename};
}

# --- Surname -------------------------------------------------------------------

sub set_surname {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{surname} = $value;
}

sub get_surname {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{surname};
}

# --- Gender -----------------------------------------------------------------------

sub set_gender {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{gender} = $value;
}

sub get_gender {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{gender};
}

# --- Location -----------------------------------------------------------------------

sub set_location {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{location} = $value;
}

sub get_location {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{location};
}

# --- Perl_Level -----------------------------------------------------------------------

sub set_perl_level {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{perl_level} = $value;
}

sub get_perl_level {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{perl_level};
}

=head1 NAME

Report::Porf::examples::Person

=head1 SYNOPSIS

Data class.

Only needed as example class for Porf examples.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
