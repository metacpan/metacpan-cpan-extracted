# ----------------------------------------------------------------------
# CLASS: ODG::Record
# ----------------------------------------------------------------------
package ODG::Record;
use 5.008;
use Moose;
	with 'MooseX::Meta::Attribute::Index';

our $VERSION = '0.30';

  # We do not install any accessors since we want to make this 
  # lvalue ready,
	has _data	=> ( 
	    isa          => 'ArrayRef'    , 
	    # predicate    => '_has_data'   ,
        default      => sub { [] }    , 
		documentaion => 'slot for holding data' ,
	);


sub _has_data {
	scalar( @{ $_[0]->_data } ) > 1;
}


# _data
#   lvalue accessor to the data slot.
sub _data :lvalue {

    $_[0]->{_data} = $_[1] if ( $_[1] );
    $_[0]->{_data};

}


# -----------------------------------------------------------------------
# FIELD ACCESSORS:
#    Create FIELD ACCESSORS for each field.
#
#  We want to install instance methods and not class methods.  The class
#  method would cause these methods to be available to subsequent classes.
#  This would be undesirable because there might be two ODG::Record objects
#  Thanks to Paul Driver     
# 
# -----------------------------------------------------------------------
sub BUILD {

	use Data::Dumper;
    my ( $self, @args ) = @_;
	my $meta = $self->meta;
	my $index;

	foreach my $field ( keys %{ $meta->get_attribute_map } ) {

		my $attr = $meta->get_attribute( $field );

	  # Check to see if each index is used only once 
		if ( $attr->can('index') ) {

			$index->{ $attr->index }++ ;
			confess( "Two fields share index: " . $attr->index ."\n" ) 
			  if ( $index->{ $attr->index } > 1 );

			if ( 
				$attr->_is_metadata and
				$attr->_is_metadata eq 'rw' 
			) {
			
			# Installs lvalue accessor
				$meta->add_method( 
					$field , 
					sub :lvalue { 

					  # Update the old value if used  second argument is passed 
						$self->{_data}->[ $attr->index ] = $_[1] if ( $_[1] ); 
        
					  # LVALUE return 
						$self->{_data}->[ $attr->index ] ;
					} 
				);

			} else {
			
				$meta->add_method( 
					$field, 
					sub { $self->{_data}->[ $attr->index ] } 
				);

			}

		}

	}

}


1;

__END__

=head1 NAME

ODG::Record - Perl extension for efficient and simple manipulation of row-based records. 

=head1 VERSION

0.30

=head1 SYNOPSIS

	package  MyClass;

		use Moose;
			extends 'ODG::Record';
			

		has first_name => (
			is 			=> 'rw' ,
			isa			=> 'Str',
			index		=> 0 ,           # Denotes ArrayRef position for attribute
			traits		=> [ 'Index' ] , # Required trait
		);

		... 


	package main;
		use ODG::Record;

		my $record = ODG::Record->new( _data => [ 'frank', 'n', 'stein' ] ) );

      # Indexed attributes are stored in the ArrayRef and can be accessed
      # as any other attribute except that 

		print $record->first_name; 		# frank

		
	  # Data can retrieved by using the _data attribute.
		$record->_data = [ 'char', 'lee', 'brown' ] ;   

		$record->first_name; # char


	  # L-value attributes can also be defined.

		$record->first_name = 'Robert'  


=head1 DESCRIPTION

THIS VERSION BREAKS BACKWARD WITH PREVIOUS VERSIONS.  THE API IS SIMPLIER.

ODG::Record is an extensible L<Moose>-based class for efficiently and 
simply working with row based records.  ArrayRefs are much faster than 
HashRefs especially for long arrays. This module circumvents the Mooses' 
HashRef based objects and places designated attributes in the _data slot, 
an ArrayRef.  This allows for construction of more efficient row-based
processing but retains the Moose flavor.

To work with a new record, simply change the reference of the _data slot.

	$record->_data( [ 'Some', 'Array', 'Ref' ] );

Since the emphasis is on speed and generally connection to tightly typed
systems such as Databases, we break the Moose encapsulation and install
our own type-checking free accessors.  Type checking is left up to the 
user.  Since we have eliminated the type-checking, we have also added 
another bit of magic, L-based accessors.  So rather than coding:

	$record->first_name( "Frank" );

You can use the much more natural appearing:

    $record->first_name = "Frank" 

This only works for attributes that are placed in the ArrayRef.   Other
attributes have normal Moose behavior.


=head1 DETAILS

Placing the record data in an ArrayRef _data slot allows far greater 
efficient when processing row-based records.  Rather than creating a
new object for each row, ODG::Record recycles the object and only swaps
the reference of the _data. Since data is stored as an ArrayRef, this 
is a huge performance win.

During object construction, name-based accessors are built for each 
record field. By default, the accessors permit L-value assignment. 


=head1 METHODS

=head2 new

Object constructor.  Creates and returns a ODG::Record object.  It
takes the following options. 


=head2 _data 

L-value object accessor to the record data.  Data is stroed internally
as an array reference, so data  This is the very fast 
accessor for the _data,    

  #  Getter
    $record->_data               # Retrieve entire array ref
    $record->_data->[ $index ]   # Get a specific field
  
  # Setter
    $record->_data( [ .. ] )
    $record->_data = [ .. ]

    $record->_data->[ $index ] = $value    



=head2 EXPORT

None by default.


=head1 SEE ALSO

L<MooseX::Meta::Attribute::Index>

L<Moose>


=head1 THANKS

Steven Little, author of L<Moose>

Paul Driver for suggesting to place the accessor methods in the instance rather than the class.

Members of moose@perl.org.


=head1 AUTHOR

Christopher Brown, E<lt>http://www.opendatagroup,comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Open Data 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
