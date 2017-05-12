package Number::Uncertainty;

=head1 NAME

Number::Uncertainty - An object-orientated uncertainty object

=head1 SYNOPSIS

  $obj = new Number::Uncertainty ( Value => $value );

  $obj = new Number::Uncertainty ( Value => $value,
                                   Error => $error_bar );

  $obj = new Number::Uncertainty ( Value => $value,
                                   Lower => $lower_error_bar,
				   Upper => $upper_error_bar );

  $obj = new Number::Uncertainty ( Value => $value,
                                   Min   => $minimum_value,
				   Max   => $maximum_value );
				   
  $obj = new Number::Uncertainty ( Value => $value,
                                   Bound => 'lower' );				   

  $obj = new Number::Uncertainty ( Value => $value,
                                   Bound => 'upper' );

=head1 DESCRIPTION

Stores information about a value and its error bounds.

=cut

# L O A D   M O D U L E S --------------------------------------------------

use strict;
use warnings;

use Carp;

# Operator overloads
use overload '""' => 'stringify',
             '==' => 'equal',
             'eq' => 'equal',
             '!=' => 'notequal',
             'ne' => 'notequal',
             '>'  => 'greater_than',
             '<'  => 'less_than',
             '*'  => 'multiply';

use vars qw/ $VERSION /;
'$Revision: 1.4 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);

# C O N S T R U C T O R ----------------------------------------------------

=head1 REVISION

$Id: Uncertainty.pm,v 1.4 2005/10/26 20:13:57 cavanagh Exp $

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance from a hash of options

  $object = new Number::Uncertainty( %hash );

returns a reference a C<Number::Uncertainty> object. 'Value' is the sole 
mandatory agruement.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # bless the query hash into the class
  my $block = bless { VALUE => undef,
                      UPPER => undef,
		      LOWER => undef,
		      BOUND => undef }, $class;

  # Configure the object
  $block->configure( @_ );

  return $block;

}

# M E T H O D S -------------------------------------------------------------

=back

=head2 Accessor Methods

=over 4

=item B<value>

Sets or gets the value of the number

   $obj->value( $val );
   $val = $obj->value();

=cut

sub value {
  my $self = shift;

  if (@_) {
     $self->{VALUE} = shift;
  }
  return $self->{VALUE};
  
}

=item B<error>

Sets or gets the value of the error

   $obj->error( $err );
   $err = $obj->error();

=cut

sub error {
  my $self = shift;

  if (@_) {
     my $error = shift;
     $self->{LOWER} = 0.5*$error;
     $self->{UPPER} = 0.5*$error;     
  }
  
  if( defined $self->bound() ) {
     return undef;
  }   
  
  my $errorbar;
  if ( defined $self->lower() && defined $self->upper() ) {
    $errorbar = abs ( $self->lower() + $self->upper() );
  } else {
    $errorbar = 0;
  }  
    
  return $errorbar;
  
}

=item B<lower>

Sets or gets the value of the lower error value

   $obj->lower( $lower );
   $lower = $obj->lower();

=cut

sub lower {
  my $self = shift;

  if (@_) {
     $self->{LOWER} = shift;  
  }
  
  if( defined $self->bound() ) {
     return undef;
  } 
  
  return $self->{LOWER};
}


=item B<upper>

Sets or gets the value of the upper error value

   $obj->upper( $upper );
   $upper = $obj->upper();

=cut

sub upper {
  my $self = shift;

  if (@_) {
     $self->{UPPER} = shift;  
  }
  
  if( defined $self->bound() ) {
     return undef;
  } 
  
  return $self->{UPPER};
}

=item B<min>

Sets or gets the value of the minimum value

   $obj->lower( $min );
   $min = $obj->min();

=cut

sub min {
  my $self = shift;

  if (@_) {
     my $min = shift;
     $self->{LOWER} = abs ( $self->value() - $min );  
  }
  
  if( defined $self->bound() ) {
     if( $self->bound() eq 'upper' ) {
        return undef;
     } elsif ( $self->bound() eq 'lower' ) {
        return $self->value(); 
     }
  }
  
  my $min;
  if( defined $self->{LOWER} ) {
     $min = $self->value() - $self->{LOWER};
  } else {
     $min = $self->value(); 
  }     
  return $min;
}


=item B<max>

Sets or gets the value of the maximum value

   $obj->max( $max );
   $max = $obj->max();

=cut

sub max {
  my $self = shift;

  if (@_) {
     my $max = shift;
     $self->{UPPER} = $max - $self->value();  
  }
  
  if( defined $self->bound() ) {
     if( $self->bound() eq 'upper' ) {
        return $self->value();
     } elsif ( $self->bound() eq 'lower' ) {
        return undef; 
     }
  }
  
  my $max;
  if( defined $self->{UPPER} ) {
     $max = $self->value() + $self->{UPPER};
  } else {
     $max = $self->value();    
  }
  return $max;
}


=item B<bound>

Flag to say whether the value() is an upper or lower bound

   $obj->bound( 'upper' );
   $obj->bound( 'lower' );
   $obj->bound( undef );
   $flag = $obj->bound();

=cut

sub bound {
  my $self = shift;

  if (@_) {
     my $flag = shift;
     if( lc ( $flag ) eq 'upper' ) {
        $self->{BOUND} = 'upper';
     } elsif ( lc ( $flag ) eq 'lower' ) {
        $self->{BOUND} = 'lower';	
     } else {
        $self->{BOUND} = undef;	
     }	
  }
  return $self->{BOUND};
}

# C O N F I G U R E -------------------------------------------------------

=back

=head2 General Methods

=over 4

=item B<configure>

Configures the object, takes an options hash as an argument

  $obj->configure( %options );

Does nothing if the array is not supplied.

=cut

sub configure {
  my $self = shift;

  # return unless we have arguments
  return undef unless @_;

  # grab the argument list
  my %args = @_;

  unless ( defined $args{"Value"} || defined $args{"value"} ) {
     croak( "Error - Number::Uncertainty: No value defined..." );
  }
  
  # Loop over the allowed keys and modify the default query options
  for my $key (qw / Value Error Lower Upper Bound Min Max / ) {
      my $method = lc($key);
      $self->$method( $args{$key} ) if exists $args{$key};
  }

}

# P R I V A T  E   M E T H O D S ------------------------------------------

=back

=head2 Operator Overloading

These operators are overloaded:

=over 4

=item B<"">

When the object is used in a string context it is stringify'ed.

=cut

sub stringify {
  my $self = shift;
  
  my $string;
  if( defined $self->bound() ) {
     if ( $self->bound() eq 'lower' ) {
        $string = "lower bound of " . $self->value();
     } elsif ( $self->bound() eq 'upper' ) {
        $string = "upper bound of " . $self->value();
     }	
  } else {
     if( $self->{UPPER} == $self->{LOWER} ) {
        $string = $self->value . " +- " . $self->{UPPER}; 
     } else {
         $string = $self->value . " + " . $self->{UPPER} . 
	           ", - " . $self->{LOWER}; 
     }
  
  }
  return $string;
}


=item B<==>

When the object is equated then we do a comparison and find whether
the two values are within the error bounds.

=cut

sub equal {
  my $self = shift;
  my $other = shift;
  
  return 0 unless defined $other;
  return 0 unless UNIVERSAL::isa($other, "Number::Uncertainty" );

  # both objects are boundary value, bugger...
  if( defined $self->bound() && defined $other->bound() ) {
     #print "Both objects are boundary objects\n";
     
     if( ( $self->bound() eq 'upper' && $self->bound() eq 'upper' ) ||
         ( $self->bound() eq 'lower' && $self->bound() eq 'lower' ) ) {
        return 1;
     }
     
     my ($lower, $upper);
     if ( $self->bound() eq 'lower' ) {
        $lower = $self->min();
	$upper = $other->max();
     } elsif ( $self->bound() eq 'upper' ) {
        $upper = $self-> max();
	$lower = $other->lower(); 	
     }
     
     if( $lower <= $upper ) {
        return 1;
     } else {
        return 0;
     }

  }
  
  # The self object is a boundary value
  if( defined $self->bound() ) {
     #print "The \$self object is a boundary objects\n";
   
     # the value is an upper bound
     if( $self->bound() eq 'upper' ) {
        if ($other->max() >= $self->max() ) {
	   return 1; 
        } else {
           return 0;
        }   
     }
     
     # the value is an lower bound
     if( $self->bound() eq 'lower' ) {
        if ( $other->min() <= $self->min() ) {
	   return 1;
        } else {
           return 0;
        }  
     }	   
  }

  # The other object is a boundary value
  if( defined $other->bound() ) {
     #print "The \$other object is a boundary objects\n";
   
     # the value is an upper bound
     if( $other->bound() eq 'upper' ) {
        if ($self->max() >= $other->max() ) {
	   return 1; 
        } else {
           return 0;
        }   
     }
     
     # the value is an lower bound
     if( $other->bound() eq 'lower' ) {
        if ( $self->min() <= $other->min() ) {
	   return 1;
        } else {
           return 0;
        }  
     }	   
  }

  # Case 1) The upper and lower bound of the $other object
  # falls within the bounds of the $self object
  if ( ( $other->value() <= $self->max() )  && 
       ( $other->value() >= $self->min() ) ) {
     return 1;
  }
  
  # Case 2) The lower bound of the $other object falls within
  # the bound of the self object, but the upper bound is outside
  if( ( $other->min() <= $self->max() ) &&
      ( $other->max() >= $self->max() ) ) {
     return 1;
  }      

  # Case 3) The upper bound of the $other object falls within
  # the bound of the self object, but the lower bound is outside
  if( ( $other->max() >= $self->min() ) &&
      ( $other->min() <= $self->min() ) ) {
     return 1;
  }
  
  # Case 4) The self object lies within the bounds of the other
  if( ( $other->max() >= $self->max() ) &&
      ( $other->min() <= $self->min() ) ) {
     return 1;
  }      
  
  # We don't have any overlap
  return 0;

}

=item B<!=>

When the object is equated then we do a comparison and find whether
the two values are within the error bounds.

=cut

sub notequal {
  my $self = shift;
  my $other = shift;
  
  return !($self->equal( $other ));  

}

=item B<greater_than>

=cut

sub greater_than {
  my $self = shift;
  my $other = shift;

  if( ! UNIVERSAL::isa( $other, "Number::Uncertainty" ) ) {
    if( defined( $self->error ) ) {
      return ( ( $self->max ) > $other );
    } else {
      return ( $self->value > $other );
    }
  } else {
    if( defined( $self->error ) ) {
      if( defined( $other->error ) ) {
        return ( $self->max > $other->min );
      } else {
        return ( $self->max > $other->value );
      }
    } else {
      if( defined( $other->error ) ) {
        return ( $self->value > $other->min );
      } else {
        return ( $self->value > $other->value );
      }
    }
  }
}

=item B<less_than>

=cut

sub less_than {
  my $self = shift;
  my $other = shift;

  if( ! UNIVERSAL::isa( $other, "Number::Uncertainty" ) ) {
    if( defined( $self->error ) ) {
      return ( ( $self->min ) < $other );
    } else {
      return ( $self->value < $other );
    }
  } else {
    if( defined( $self->error ) ) {
      if( defined( $other->error ) ) {
        return ( $self->min < $other->max );
      } else {
        return ( $self->min < $other->value );
      }
    } else {
      if( defined( $other->error ) ) {
        return ( $self->value < $other->max );
      } else {
        return ( $self->value < $other->value );
      }
    }
  }
}

=item B<*>

When the object is multiplied.

=cut

sub multiply {
  my $self = shift;
  my $other = shift;
  
  if ( !UNIVERSAL::isa( $other, "Number::Uncertainty" ) ) {
     if( defined $self->error()  ) {
        my $value = $self->value()*$other;
        my $error = $self->error();
        return  new Number::Uncertainty( Value => $value, Error => $error );
     } else {
        my $value = $self->value()*$other;
        return  new Number::Uncertainty( Value => $value );
     }
  }
     
  my $value = $self->value() * $other->value();
  if( defined $self->bound() || defined $other->bound() ) {
    return new Number::Uncertainty( Value => $value );
  }
  
  if( defined $self->error() && defined $other->error() ) {
    my $error = sqrt ( $self->error()*$self->error() +
                       $other->error()*$other->error() );  
    return new Number::Uncertainty( Value => $value, Error => $error );
  }

}

=back 

=head1 COPYRIGHT

Copyright (C) 2005 University of Exeter. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,

=cut

# L A S T  O R D E R S ------------------------------------------------------

1;                                                                  
