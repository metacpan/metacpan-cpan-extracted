package Perl::Dist::WiX::Util::Machine;

=pod

=head1 NAME

Perl::Dist::WiX::Util::Machine - Generate an entire set of related distributions

=head1 VERSION

This document describes Perl::Dist::WiX::Util::Machine version 1.500002.

=head1 SYNOPSIS

	# This is what Perl::Dist::Strawberry will do, as of version 2.03.

	# Create the machine
	my $machine = Perl::Dist::WiX::Util::Machine->new(
		class  => 'Perl::Dist::Strawberry',
		common => [ forceperl => 1 ],
		skip   => [4, 6],
	);

	# Set the different versions
	$machine->add_dimension('version');
	$machine->add_option('version',
		perl_version => '5101',
	);
	$machine->add_option('version',
		perl_version => '5101',
		portable     => 1,
	);
	$machine->add_option('version',
		perl_version => '5121',
		relocatable  => 1,
	);

	# Set the different paths
	$machine->add_dimension('drive');
	$machine->add_option('drive',
		image_dir => 'C:\strawberry',
	);
	$machine->add_option('drive',
		image_dir => 'D:\strawberry',
		msi       => 1,
		zip       => 0,
	);

	$machine->run();
	# Creates 8 distributions (really 6, because you can't have
	# portable => 1 and zip => 0 for the same distribution,
	# nor do we need to build a relocatable version twice.)	

=head1 DESCRIPTION

Perl::Dist::WiX::Util::Machine is a Perl::Dist::WiX multiplexer.

It provides the functionality required to generate several
variations of a distribution at the same time.

=cut

#<<<
use 5.010;
use Moose 0.90;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose         qw( Str ArrayRef HashRef Bool Int );
use Params::Util                 qw( _IDENTIFIER _HASH0 _DRIVER _CLASSISA );
use English                      qw( -no_match_vars );
use File::Copy                   qw();
use File::Copy::Recursive        qw();
use File::Path              2.08 qw( remove_tree );
use File::Spec::Functions        qw( catdir );
use File::Remove                 qw();
use File::HomeDir                qw();
use List::MoreUtils              qw( none );
use WiX3::Traceable              qw();
use Perl::Dist::WiX::Exceptions  qw();
#>>>

our $VERSION = '1.500002';

=head1 INTERFACE

=head2 new

	my $machine = Perl::Dist::WiX::Util::Machine->new(
		class => 'Perl::Dist::WiX',
		common => { forceperl => 1, },
		output => 'C:\',
		trace  => 2,
	);

This method creates a new object that generates multiple distributions,
using the parameters below.

=head3 class (required)

This required parameter specifies the class that this object uses to 
create distributions.

It must be a subclass of L<Perl::Dist::WiX|Perl::Dist::WiX>.

=cut



has class => (
	is  => 'ro',
	isa => subtype(
		'Str' => where {
			$_ ||= q{};
			_CLASSISA( $_, 'Perl::Dist::WiX' );
		},
		message {
			'Not a subclass of Perl::Dist::WiX.';
		},
	),
	required => 1,
	reader   => '_get_class',
);



=head3 common

This required parameter specifies the parameters that are common to all 
the distributions that will be created, as an array or hash reference.

For the parameters that you can put here, see the documentation for the
class that is specified in the C<'class'> parameter and its subclasses.

=cut



has common => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef,
	required => 1,
	handles  => { '_get_common' => 'elements', },
);



=head3 output (optional)

This is the directory where all the output files will be copied to.

If none is specified, it defaults to what L<File::HomeDir|File::HomeDir>
thinks is the desktop.

=cut



has output => (
	is      => 'ro',
	isa     => Str,
	default => sub { return File::HomeDir->my_desktop(); },
	reader  => '_get_output',
);



=head3 skip (optional)

This is a reference to a list of distributions to skip building, in numerical order.

Note that the numerical order the distributions is dependent on which order 
you put the dimensions in - the last dimension is changed first. For 
example, if there are 3 dimensions, with the first dimension having 3 
options and the other 2 dimensions having 2 options, the numbering is 
as follows:

   1: 1, 1, 1   2: 1, 1, 2   3: 1, 2, 1   4: 1, 2, 2
   5: 2, 1, 1 ...   
   9: 3, 1, 1 ...

If you wanted to skip the two distributions where the first dimension was 
going to use its second option and the last dimension was going to use its 
first option, you would pass [ 5, 7 ] to this option.
   
=cut



has skip => (
	traits  => ['Array'],
	is      => 'bare',
	isa     => ArrayRef,
	default => sub { return [0]; },
	handles => { '_get_skip_values' => 'elements', },
);



=head3 trace (optional)

This is the trace level for all objects.

If none is specified, it defaults to 1.

=cut



has trace => (
	is      => 'ro',
	isa     => Int,
	default => 1,
	reader  => '_get_trace',
);



has _dimensions => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef,
	default  => sub { return []; },
	init_arg => undef,
	handles  => {
		'_add_dimension'  => 'push',
		'_get_dimensions' => 'elements',
	},
);

has _options => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef,
	default  => sub { return {}; },
	init_arg => undef,
	handles  => {
		'_set_options'   => 'set',
		'_option_exists' => 'exists',
		'_get_options'   => 'get',

	},
);

has _state => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef,
	default  => sub { return {} },
	init_arg => undef,
	handles  => {
		'_has_state' => 'count',
		'_set_state' => 'set',
		'_get_state' => 'get',
	},
);

has _eos => (
	traits   => ['Bool'],
	is       => 'bare',
	isa      => Bool,
	default  => 0,
	init_arg => undef,
	reader   => '_get_eos',
	handles  => { '_set_eos' => 'set', },
);

has _traceobject => (
	is       => 'bare',
	init_arg => undef,
	lazy     => 1,
	reader   => '_get_traceobject',
	builder  => '_build_traceobject',
);

sub _build_traceobject {
	my $self = shift;

	return WiX3::Traceable->new( tracelevel => $self->_get_trace() );
}


#####################################################################
# Constructor

sub BUILDARGS {
	my $class = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw( 'Parameters incorrect (not a hashref or hash)'
			  . 'for Perl::Dist::WiX::Util::Machine' );
	}

	if ( _HASH0( $args{common} ) ) {
		$args{common} = [ %{ $args{common} } ];
	}

	return \%args;
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	# Check params
	if ( not _DRIVER( $self->_get_class(), 'Perl::Dist::WiX' ) ) {
		PDWiX->throw('Missing or invalid class param');
	}

	my $output = $self->_get_output();
	if ( not -d $output or not -w $output ) {
		PDWiX->throw( "The output directory '$output' does not "
			  . 'exist, or is not writable' );
	}

	return $self;
} ## end sub BUILD




#####################################################################
# Setup Methods

=head2 add_dimension

	$machine->add_dimension('perl_version');

Adds a 'dimension' (a set of options for different distributions) to the 
machine. 

The options are added by L<add_option|/add_option> calls using this 
dimension name.

Note that dimensions are multiplicative, so that if there are 3 dimensions 
defined in the machine, and they each have 3 options, 27 distributions will be 
generated.

=cut



sub add_dimension {
	my $self = shift;
	my $name = _IDENTIFIER(shift)
	  or PDWiX->throw('Missing or invalid dimension name');
	if ( $self->_has_state() ) {
		PDWiX->throw('Cannot alter params once iterating');
	}
	if ( $self->_option_exists($name) ) {
		PDWiX->throw("The dimension '$name' already exists");
	}

	$self->_add_dimension($name);
	$self->_set_options( $name => [] );
	return 1;
} ## end sub add_dimension



=head2 add_option

  $machine->add_option('perl_version',
    perl_version => '5120',
    relocatable => 1,
  );

Adds a 'option' (a set of parameters that can change) to a dimension. 

The first parameter is the dimension to add the option to, and the 
other parameters are stored in the dimension to be used when creating
objects.

The combination of the C<'common'> parameters and one option from each
dimension is used when creating or iterating through distribution objects.

=cut



sub add_option {
	my $self = shift;
	my $name = _IDENTIFIER(shift)
	  or PDWiX->throw('Missing or invalid dimension name');
	if ( $self->_has_state() ) {
		PDWiX->throw('Cannot alter params once iterating');
	}
	if ( not $self->_option_exists($name) ) {
		PDWiX->throw("The dimension '$name' does not exist");
	}
	my $option = $self->_get_options($name);
	push @{$option}, [@_];
	$self->_set_options( $name => $option );
	return 1;
} ## end sub add_option




#####################################################################
# Iterator Methods

sub _increment_state {
	my $self = shift;
	my $name = shift;

	my $number = $self->_get_state($name);
	$self->_set_state( $name, ++$number );

	return;
}



=head2 all

	my @dists = $machine->all();

Returns an array of objects that create all the possible 
distributions configured for this machine. 

=cut



sub all {
	my $self    = shift;
	my @objects = ();
	while (1) {
		my $object = $self->next() or last;
		push @objects, $object;
	}
	return @objects;
}



=head2 next

	my $dist = $machine->next();

Returns an object that creates the next possible 
distribution that is configured for this machine. 

=cut



sub next { ## no critic (ProhibitBuiltinHomonyms)
	## no critic (ProhibitExplicitReturnUndef)
	my $self = shift;
	if ( $self->_get_eos() ) {

		# Already at last state
		return undef;
	}

	# Initialize the iterator if needed
	if ( $self->_has_state() ) {

		# Move to the next position
		my $found = 0;
		foreach my $name ( $self->_get_dimensions() ) {
			if ( $self->_get_state($name) !=
				$#{ $self->_get_options($name) } )
			{

				# Normal iteration
				$self->_increment_state($name);
				$found = 1;
				last;
			}

			# We've hit the end of a dimension.
			# Loop the state to the start, so the
			# next dimension will iterate to the
			# correct value.
			$self->_set_state( $name => 0 );
		} ## end foreach my $name ( $self->_get_dimensions...)
		if ( not $found ) {
			$self->_set_eos();
			return undef;
		}
	} else {

		# Initialize to the first position
		my %state;
		foreach my $name ( $self->_get_dimensions() ) {
			if ( not @{ $self->_get_options($name) } ) {
				PDWiX->throw("No options for dimension '$name'");
			}
			$state{$name} = 0;
		}
		$self->_set_state(%state);

	} ## end else [ if ( $self->_has_state...)]

	# Create the parameter-set
	my @params = $self->_get_common();
	foreach my $name ( $self->_get_dimensions() ) {
		my $i = $self->_get_state($name);
		push @params, @{ $self->_get_options($name)->[$i] };
	}
	push @params, ( '_trace_object' => $self->_get_traceobject() );
	push @params, ( 'trace'         => $self->_get_trace() );

	# Create the object with those params
	return $self->_get_class()->new(@params);
} ## end sub next





#####################################################################
# Execution Methods



=head2 run

	$machine->run();

Tries to create and execute each object that can be created by this 
machine.

=cut



sub run {
	my $self       = shift;
	my $success    = 0;
	my $output_dir = $self->_get_output();
	my $num        = 0;

	while ( my $dist = $self->next() ) {
		$dist->prepare();
		$num++;
		if ( none { $_ == $num } $self->_get_skip_values() ) {
			$success = eval { $dist->run(); 1; };

			if ($success) {

				# Copy the output products for this run to the
				# main output area.
				foreach my $file ( $dist->get_output_files() ) {
					File::Copy::copy( $file, $output_dir );
				}
				File::Copy::Recursive::dircopy( $dist->output_dir(),
					catdir( $output_dir, "success-output-$num" ) );
				File::Copy::Recursive::dircopy( $dist->fragment_dir(),
					catdir( $output_dir, "success-fragments-$num" ) );
			} else {
				print $EVAL_ERROR;
				File::Copy::Recursive::dircopy( $dist->output_dir(),
					catdir( $output_dir, "error-output-$num" ) );
			}
		} else {
			print "\n\nSkipping build number $num.";
		}

		print "\n\n\n\n\n";
		print q{-} x 60;
		print "\n\n\n\n\n";

		# Flush out the image dir for the next run
		my $err;
		my $dir = $dist->image_dir();
		remove_tree(
			"$dir",
			{   keep_root => 1,
				error     => \$err,
			} );
		my $e = $EVAL_ERROR;

		if ($e) {
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to remove directory, critical error:\n$e"
			);
		}
		if ( @{$err} ) {
			my $errors = q{};
			for my $diag ( @{$err} ) {
				my ( $file, $message ) = %{$diag};
				if ( $file eq q{} ) {
					$errors .= "General error: $message\n";
				} else {
					$errors .= "Problem removing $file: $message\n";
				}
			}
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to remove directory, errors:\n$errors"
			);
		} ## end if ( @{$err} )
	} ## end while ( my $dist = $self->next...)
	return 1;
} ## end sub run

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>adamk@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
