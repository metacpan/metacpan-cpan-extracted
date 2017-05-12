
package R::YapRI::Robject::Rattributes;

use strict;
use warnings;
use autodie;

use Carp qw( carp croak cluck );


###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI::Robject::Rattributes

A module to store R attributes for an object

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use R::YapRI::Robject::Rattributes;

  my $rattr = R::YapRI::Rattributes->new();

  $rattr->set_names(["X", "Y"]);
  my @names = @{$rattr->get_names()};

  $rattr->set_dim([5,5]);
  my @dim = @{$attr->get_dim()};

  $rattr->set_dimnames([["a", "b", "c"], ["x", "y", "z"]]);
  my @dimnames_arefs = @{$rattr->set_dimnames()};

  $rattr->set_rownames(["x", "y", "z"]);
  my @rownames_arefs = @{$rattr->set_rownames()};
  
  $rattr->set_class("data.frame");
  my $class = $attr->get_class();

  $rattr->set_tsp($start, $end, $frequency);
  my ($start, $end, $frequency) = $attr->get_tsp();


=head1 DESCRIPTION

Create a R::YapRI::Robject::Rattributes object, used by L<R::YapRI::Robject>
to define the attributes for an Robject.

There are 5 basic attributes for R objects (names, dim, dimnames, class and tsp)
(for more info L<http://cran.r-project.org/doc/manuals/R-lang.html#Attributes>)

It also has an special case, row.names for data.frames.

=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



############################
### GENERAL CONSTRUCTORS ###
############################

=head1 (*) CONSTRUCTORS:

It has a simple constructor using new() function.

Any of the accessors can be used as function arguments to set the accessor
value during the object creation.

=head2 constructor new

  Usage: my $rattr = R::YapRI::Robject::Rattributes->new($acc_href);

  Desc: Create a new R::YapRI::Robject::Rattributes object.

  Ret: a R::YapRI::Robject::Rattributes object

  Args: $acc_href, an accessor hash ref. with the following key/value pairs:
        names    => arrayref. of strings (generally used with vectors and lists)
        dim      => arrayref. of positive integers.
        dimnames => arrayref. of arrayref. of strings.
        rownames => arrayref. of rownames (generally used with data.frames)
        class    => an scalar defining the class
        tsp      => an arrayref. with three members: start, end and frequency.
        
  Side_Effects: Die if the accessor hashref. is not a hash ref. or it is 
                has a different accessor than names, dim, dimnames, class or
                tsp.

  Example: my $rattr = R::YapRI::Robject::Rattributes->new($acc_href);        

=cut

sub new {
    my $class = shift;
    my $acchref = shift;

    my $self = bless( {}, $class ); 

    ## Check variables.

    my %accs = ();
    if (defined $acchref) {
	if (ref($acchref) ne 'HASH') {
	    croak("ARG. ERROR: $acchref supplied to new() isnt an HASHREF.");
	}
	else {
	    %accs = %{$acchref};
	}
    }

    ## Permitted accessors

    my %permacc = (
	names    => [],
	dim      => [],
	dimnames => [[]],
	rownames => [],
	class    => '',
	tsp      => ['', '', ''],
	);
    
    foreach my $acc (sort keys %accs) {
	unless (defined $permacc{$acc}) {
	    croak("ARG. ERROR: accessor name $acc isnt permited for new()");
	}
    }

    ## Add default values (empty variables) and set the accessors

    foreach my $pacc (sort keys %permacc) {
	
	my $acc_function = 'set_' . $pacc;

	unless (defined $accs{$pacc}) {
	    $self->$acc_function($permacc{$pacc});
	}
	else {
	    $self->$acc_function($accs{$pacc});
	}
    }

    return $self;
}


#################
### ACCESSORS ###
#################

=head1 (*) ACCESSORS:

There are a couple of functions (get/set) for accessors

=head2 get/set_names

  Usage: my $names_aref = $rattr->get_names();
         $rattr->set_names($names_aref); 

  Desc: Get/Set the names attributes to Rattributes object

  Ret: Get: $names_aref, an array ref. with names attribute
       Set: None

  Args: Get: None
        Set: $names_aref, an array ref. with names attribute

  Side_Effects: Get: None
                Set: Die if the argument supplied is not an array ref.

  Example: my @names = @{$rattr->get_names()};
           $rattr->set_names(\@names); 

=cut

sub get_names {
    my $self = shift;
    return $self->{names};
}

sub set_names {
    my $self = shift;
    my $names_aref = shift;

    unless (defined $names_aref) {
	croak("ERROR: No argument was supplied to set_names function.");
    }
    else {
	if (ref($names_aref) ne 'ARRAY') {
	    croak("ERROR: $names_aref supplied to set_names isnt an ARRAYREF.");
	}
    }

    $self->{names} = $names_aref;
}


=head2 get/set_dim

  Usage: my $dim_aref = $rattr->get_dim();
         $rattr->set_dim($dim_aref); 

  Desc: Get/Set the dim (dimension) attribute to Rattributes object

  Ret: Get: $dim_aref, an array ref. with dim (integers) attribute
       Set: None

  Args: Get: None
        Set: $dim_aref, an array ref. with dim (integers) attribute

  Side_Effects: Get: None
                Set: Die if the argument supplied is not an array ref.
                     Die if the elements of the array ref. are not integers.

  Example: my @dim = @{$rattr->get_dim()};
           $rattr->set_dim(\@dim); 

=cut

sub get_dim {
    my $self = shift;
    return $self->{dim};
}

sub set_dim {
    my $self = shift;
    my $dim_aref = shift;

    unless (defined $dim_aref) {
	croak("ERROR: No argument was supplied to set_dim function.");
    }
    else {
	if (ref($dim_aref) ne 'ARRAY') {
	    croak("ERROR: $dim_aref supplied to set_dim isnt an ARRAYREF.");
	}
	else {
	    foreach my $dim (@{$dim_aref}) {
		if ($dim !~ m/^\d+$/) {
		    croak("ERROR: dim=$dim used at set_dim isnt an INTEGER.");
		}
	    }
	}
    }

    $self->{dim} = $dim_aref;
}


=head2 get/set_dimnames

  Usage: my $dimnames_arefaref = $rattr->get_dimnames();
         $rattr->set_dimnames($dimnames_arefaref); 

  Desc: Get/Set the dimnames attribute to Rattributes object.

  Ret: Get: $dimnames_arefaref, an array ref. of array references 
            with dimnames attributes
       Set: None

  Args: Get: None
        Set: $dimnames_arefaref, an array ref. of array references 
             with dimnames attribute

  Side_Effects: Get: None
                Set: Die if the argument supplied is not an array ref.
                     Die if the elements of the array ref. are not array refs.

  Example: my @dimnames_aref = @{$rattr->get_dimnames()};
           $rattr->set_dimnames([ ['A', 'B'], ['x', 'y'] ]); 

=cut

sub get_dimnames {
    my $self = shift;
    return $self->{dimnames};
}

sub set_dimnames {
    my $self = shift;
    my $dns_afaf = shift;

    unless (defined $dns_afaf) {
	croak("ERROR: No argument was supplied to set_dimnames function.");
    }
    else {
	if (ref($dns_afaf) ne 'ARRAY') {
	    croak("ERROR: $dns_afaf supplied to set_dimnames isnt ARRAYREF.");
	}
	else {
	    foreach my $dns_af (@{$dns_afaf}) {
		if (ref($dns_af) ne 'ARRAY') {
		    croak("ERROR: $dns_af used at set_dimnames isnt an AREF.");
		}
	    }
	}
    }

    $self->{dimnames} = $dns_afaf;
}

=head2 get/set_rownames

  Usage: my $rownames_aref = $rattr->get_rownames();
         $rattr->set_rownames($rownames_aref); 

  Desc: Get/Set the row.names attributes to Rattributes object

  Ret: Get: $rownames_aref, an array ref. with row.names attribute
       Set: None

  Args: Get: None
        Set: $rownames_aref, an array ref. with row.names attribute

  Side_Effects: Get: None
                Set: Die if the argument supplied is not an array ref.

  Example: my @rownames = @{$rattr->get_rownames()};
           $rattr->set_rownames(\@rownames); 

=cut

sub get_rownames {
    my $self = shift;
    return $self->{rownames};
}

sub set_rownames {
    my $self = shift;
    my $rowns_aref = shift;

    unless (defined $rowns_aref) {
	croak("ERROR: No argument was supplied to set_rownames function.");
    }
    else {
	if (ref($rowns_aref) ne 'ARRAY') {
	    croak("ERROR: $rowns_aref supplied to set_rownames isnt an AREF.");
	}
    }

    $self->{rownames} = $rowns_aref;
}

=head2 get/set_class

  Usage: my $class = $rattr->get_class();
         $rattr->set_class($class); 

  Desc: Get/Set the class attribute to Rattributes object

  Ret: Get: $class, a class attribute for an R object
       Set: None

  Args: Get: None
        Set: $class, a class attribute for an R object

  Side_Effects: Get: None
                Set: Die if no arguments is supplied to this function

  Example: my $class = @{$rattr->get_class()};
           $rattr->set_class($class); 

=cut

sub get_class {
    my $self = shift;
    return $self->{class};
}

sub set_class {
    my $self = shift;
    my $class = shift;

    unless (defined $class) {
	croak("ERROR: No argument was supplied to set_class function.");
    }
    elsif (ref($class)) {
	croak("ERROR: $class supplied to set_class is not a string/scalar")
    }

    $self->{class} = $class;
}

=head2 get/set_tsp

  Usage: my $tsp_aref = $rattr->get_tsp();
         $rattr->set_tsp($tsp_aref); 

  Desc: Get/Set the tsp (time series) attribute to Rattributes object

  Ret: Get: $tsp_aref, a tsp array ref. attribute for an R object with three
            elements: $start, $end, $frequency.
       Set: None

  Args: Get: None
        Set: $tsp_aref, a tsp array ref. attribute for an R object with three
            elements: $start, $end, $frequency.

  Side_Effects: Get: None
                Set: Die if no arguments is supplied to this function.
                     Die if the argument provided is not an array ref.
                     If the array ref. supplied has more than three elements,
                     that array will be modify and the elements beyond 3 will
                     be deleted (last index of the array will be set to 2)

  Example: my ($start, $end, $frequency) = @{$rattr->get_tsp()};
           $rattr->set_class([$start, $end, $frequency]); 

=cut

sub get_tsp {
    my $self = shift;
    return $self->{tsp};
}

sub set_tsp {
    my $self = shift;
    my $tsp_aref = shift;

    unless (defined $tsp_aref) {
	croak("ERROR: No argument was supplied to set_tsp function.");
    }
    else {
	if (ref($tsp_aref) ne 'ARRAY') {
	    croak("ERROR: $tsp_aref supplied to set_tsp is not an ARRAYREF.");
	}
	if (scalar(@{$tsp_aref}) > 3) {

	    ## Modify the array ref. and cut just to take 3 elements.
	    $#$tsp_aref = 2;
	}
    }

    $self->{tsp} = $tsp_aref;
}




=head1 ACKNOWLEDGEMENTS

Lukas Mueller

Robert Buels

Naama Menda

Jonathan "Duke" Leto

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Boyce Thompson Institute for Plant Research

Copyright 2011 Sol Genomics Network (solgenomics.net)

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

####
1; #
####
