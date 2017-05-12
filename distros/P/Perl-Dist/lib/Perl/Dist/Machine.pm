package Perl::Dist::Machine;

=pod

=head1 NAME

Perl::Dist::Machine - Generate an entire set of related distributions

=head1 DESCRIPTION

Perl::Dist::Machine is a Perl::Dist multiplexor.

It provides the functionality required to generate several
variations of a distribution at the same time.

Please note the API is still evolving, and as such will remain
undocumented for now.

However, if you are adventurous and happy to read the source code,
it should be pretty clear.

=cut

use 5.005;
use strict;
use Carp          'croak';
use File::Copy    ();
use Params::Util  qw{ _STRING _IDENTIFIER _ARRAY0 _HASH0 _DRIVER };
use File::HomeDir ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	class
	output
	state
};





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# All passed arguments go into the common param pool by default
	my $self = bless { @_,
		dimensions => [ ],
		options    => { },
		state      => undef,
		eos        => 0, # End of State
	}, $class;

	# Check params
	unless ( 
		_DRIVER($self->class, 'Perl::Dist::Inno') or
		_DRIVER($self->class, 'Perl::Dist::WiX') ) {
		croak("Missing or invalid class param");
	}
	unless ( defined $self->output ) {
		$self->{output} = File::HomeDir->my_desktop;
	}
	unless ( _STRING($self->output) ) {
		croak("Missing or invalid output param");
	}
	unless ( -d $self->output and -w $self->output ) {
		my $output = $self->output;
		croak("The output directory '$output' does not exist, or is not writable");
	}
	if ( _HASH0($self->{common}) ) {
		$self->{common} = [ %{ $self->{common} } ];
	}
	unless ( _ARRAY0($self->{common}) ) {
		croak("Did not provide a common param");
	}

	return $self;
}

sub common {
	return @{$_[0]->{common}};
}

sub dimensions {
	return @{$_[0]->{dimensions}};
}





#####################################################################
# Setup Methods

sub add_dimension {
	my $self = shift;
	my $name = _IDENTIFIER(shift) or croak("Missing or invalid dimension name");
	if ( defined $self->state ) {
		croak("Cannot alter params once iterating");
	}
	if ( $self->{options}->{$name} ) {
		croak("The dimension '$name' already exists");
	}
	push @{ $self->{dimensions} }, $name;
	$self->{options}->{$name} = [ ];
	return 1;
}

sub add_option {
	my $self = shift;
	my $name = _IDENTIFIER(shift) or croak("Missing or invalid dimension name");
	if ( defined $self->state ) {
		croak("Cannot alter params once iterating");
	}
	unless ( $self->{options}->{$name} ) {
		croak("The dimension '$name' does not exist");
	}
	push @{ $self->{options}->{$name} }, [ @_ ];
	return 1;
}





#####################################################################
# Iterator Methods

sub all {
	my $self    = shift;
	my @objects = ();
	while ( 1 ) {
		my $object = $self->next or last;
		push @objects, $object;
	}
	return @objects;
}

sub next {
	my $self = shift;
	if ( $self->{eos} ) {
		# Already at last state
		return undef;
	}

	# Initialize the iterator if needed
	my $options = $self->{options};
	my $state   = $self->state;
	if ( $state ) {
		# Move to the next position
		my $found = 0;
		foreach my $name ( $self->dimensions ) {
			unless ( $state->{$name} == $#{ $options->{$name} } ) {
				# Normal iteration
				$state->{$name}++;
				$found = 1;
				last;
			}

			# We've hit the end of a dimension.
			# Loop the state to the start, so the
			# next dimension will iterate to the
			# correct value.
			$state->{$name} = 0;
		}
		unless ( $found ) {
			$self->{eos} = 1;
			return undef;
		}
	} else {
		# Initialize to the first position
		$state = $self->{state} = { };
		foreach my $name ( $self->dimensions ) {
			unless ( @{ $options->{$name} } ) {
				croak("No options for dimension '$name'");
			}
			$state->{$name} = 0;
		}
	}

	# Create the param-set
	my @params = $self->common;
	foreach my $name ( $self->dimensions ) {
		push @params, @{ $options->{$name}->[ $state->{$name} ] };
	}

	# Create the object with those params
	return $self->class->new( @params );
}





#####################################################################
# Execution Methods

sub run {
	my $self = shift;
	while ( my $dist = $self->next ) {
		$dist->prepare;
		$dist->run;

		# Copy the output products for this run to the
		# main output area.
		foreach my $file ( @{$dist->output_file} ) {
			File::Copy::move( $file, $self->output );
		}

		# Flush out the image dir for the next run
		File::Remove::remove(\1, $dist->image_dir);
	}
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
