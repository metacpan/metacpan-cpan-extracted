# perl
#
# Person example class
#
# PORF Perl Open Report Framework
#
# Ralf Peine, Wed May 14 10:39:48 2014
#
#------------------------------------------------------------------------------

use warnings;
use strict;

package Report::Porf::examples::Person;

# --- create Instance -----------------
sub new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;
    
    # let the class go
    my $self = {};
    bless $self, $class;

    return $self;
}

#--------------------------------------------------------------------------------
#
#  Attributes
#
#--------------------------------------------------------------------------------

# --- Count ---------------------------------------------------------------------

sub set_count {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{Count} = $value;
}

sub get_count {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{Count};
}

# --- Prename -------------------------------------------------------------------

sub set_prename {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{Prename} = $value;
}

sub get_prename {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{Prename};
}

# --- Surname -------------------------------------------------------------------

sub set_surname {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{Surname} = $value;
}

sub get_surname {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{Surname};
}

# --- Age -----------------------------------------------------------------------

sub set_age {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{Age} = $value;
}

sub get_age {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{Age};
}

# --- Time ----------------------------------------------------------------------

sub set_time {
	my ($self,        # instance_ref
		$value        # value to set
	) = @_;

	$self->{Time} = $value;
}

sub get_time {
	my ($self,        # instance_ref
	) = @_;
	
	return $self->{Time};
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
