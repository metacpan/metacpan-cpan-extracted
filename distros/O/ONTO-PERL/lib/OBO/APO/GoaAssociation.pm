# $Id: GoaAssociation.pm 2010-09-29 erick.antezana $
#
# Module  : GoaAssociation.pm
# Purpose : GOA associaton entry structure.
# License : Copyright (c) 2006 ONTO-perl. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.

package OBO::APO::GoaAssociation;

=head1 NAME

OBO::APO::GoaAssociation - A GOA association record.

=head1 SYNOPSIS

use OBO::APO::GoaAssociation;
use strict;

# three new assoc's
my $goa_association1 = OBO::APO::GoaAssociation->new();
my $goa_association2 = OBO::APO::GoaAssociation->new();
my $goa_association3 = OBO::APO::GoaAssociation->new();

$goa_association1->assc_id("APO:vm");
$goa_association1->description("this is a description");

$goa_association2->assc_id("APO:ls");
$goa_association3->assc_id("APO:ea");

my $goa_association4 = $goa_association3;

my $goa_association5 = OBO::APO::GoaAssociation->new();
$goa_association5->assc_id("APO:vm");
$goa_association5->description("this is a description");


=head1 DESCRIPTION

A goa_association object encapsulates the structure of a GOA association record.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by ONTO-perl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;
use Carp;

sub new {
        my $class                   = shift;
        my $self                    = {};
        
        $self->{ASSC_ID}     		= ""; # required, scalar (1), unique association identifier
        $self->{OBJ_SRC}            = ""; # required, scalar (1), source database of the DB object (here protein) being annotated
        $self->{OBJ_ID}           	= ""; # required, scalar (1), DB object (here protein) ID in the source DB 
        $self->{OBJ_SYMB}			= ""; # required, scalar (1), (unique and valid) symbol to which object ID is matched
        $self->{QUALIFIER}			= ""; # scalar (0..1), flags modifying the interpretation of an annotation
        $self->{GO_ID}				= ""; # required, scalar (1), GO term ID
        $self->{REFER}				= ""; # required, scalar (1), reference cited to support the annotation, format database:reference
        $self->{EVID_CODE}			= ""; # required, scalar (1), evidence code (IMP, IC, IGI, IPI, ISS, IDA, IEP, IEA, TAS, NAS, NR, ND or RCA)
        $self->{SUP_REF}			= ""; # scalar (0..1), an additional identifier to support annotations, format database:ID
        $self->{ASPECT}				= ""; # required, scalar (1), P (biological process), F (molecular function), C (cellular component)
        $self->{DESCRIPTION}        = ""; # scalar (0..1), name(s) of gene/protein (optional), abbreviated description
        $self->{SYNONYM}			= ""; # required, scalar (1), here Iternational Protein Index identifier 
        $self->{TYPE}           	= ""; # required, scalar (1), kind of entity being annotated (here protein)
        $self->{TAXON}           	= ""; # required, scalar (1), NCBI identifier for the species being annotated, format taxon:ID
        $self->{DATE}           	= ""; # required, scalar (1), the date of last annotation update in the format 'YYYYMMDD' 
        $self->{ANNOT_SRC}          = ""; # required, scalar (1)), attribute describing the source of the annotation
        
        bless ($self, $class);
        return $self;
}

=head2 assc_id

  Usage    - print $goa_association->assc_id() or $goa_association->assc_id($assc_id)
  Returns  - the association ID  (string)
  Args     - the association ID (string)
  Function - gets/sets the association ID
  
=cut
sub assc_id {
	my $self = shift;
    if (@_) {
    	$self->{ASSC_ID} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{ASSC_ID};
}
=head2 obj_src

  Usage    - print $goa_association->obj_src() or $goa_association->obj_src($obj_src)
  Returns  - the source database of the object being annotated (string)
  Args     - the source database of the object being annotated (string)
  Function - gets/sets the source database of the object being annotated 
  
=cut
sub obj_src {
	my $self = shift;
    if (@_) {
    	$self->{OBJ_SRC} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{OBJ_SRC};
}

=head2 obj_id

  Usage    - print $goa_association->obj_id() or $goa_association->obj_id($obj_id)
  Returns  - the ID of the object being annotated (string)
  Args     - the ID of the object being annotated (string)
  Function - gets/sets the ID of the object being annotated 
  
=cut
sub obj_id {
	my $self = shift;
    if (@_) {
    	$self->{OBJ_ID} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{OBJ_ID};
}

=head2 obj_symb

  Usage    - print $goa_association->obj_symb() or $goa_association->obj_symb($obj_symb)
  Returns  - the symbol of the object being annotated (string)
  Args     - the symbol of the object being annotated (string)
  Function - gets/sets the symbol of the object being annotated 
  
=cut
sub obj_symb {
	my $self = shift;
    if (@_) {
    	$self->{OBJ_SYMB} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{OBJ_SYMB};
}

=head2 qualifier

  Usage    - print $goa_association->qualifier() or $goa_association->qualifier($qualifier)
  Returns  - the qualifier of the annotation (string)
  Args     - the qualifier of the annotation (string)
  Function - gets/sets the qualifier of the annotation 
  
=cut
sub qualifier {
	my $self = shift;
    if (@_) {
    	$self->{QUALIFIER} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{QUALIFIER};
}

=head2 go_id

  Usage    - print $goa_association->go_id() or $goa_association->go_id($go_id)
  Returns  - the GO term ID associated with the object (string)
  Args     - the GO term ID associated with the object (string)
  Function - gets/sets the GO term ID associated with the object 
  
=cut
sub go_id {
	my $self = shift;
    if (@_) {
    	$self->{GO_ID} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{GO_ID};
}
=head2 refer

  Usage    - print $goa_association->refer() or $goa_association->refer($refer)
  Returns  - the reference cited to support the annotation (string)
  Args     - the reference cited to support the annotationt (string)
  Function - gets/sets the reference cited to support the annotation 
  
=cut
sub refer {
	my $self = shift;
    if (@_) {
    	$self->{REFER} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{REFER};
}

=head2 evid_code

  Usage    - print $goa_association->evid_code() or $goa_association->evid_code($evid_code)
  Returns  - the code of the supporting evidence (string)
  Args     - the code of the supporting evidence (string)
  Function - gets/sets the code of the supporting evidence
  
=cut
sub evid_code {
	my $self = shift;
    if (@_) {
    	$self->{EVID_CODE} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{EVID_CODE};
}
=head2 sup_ref

  Usage    - print $goa_association->sup_ref() or $goa_association->sup_ref($sup_ref)
  Returns  - the supplementary reference to support annotation (string)
  Args     - the supplementary reference to support annotation (string)
  Function - gets/sets the supplementary reference to support annotation
  
=cut
sub sup_ref {
	my $self = shift;
    if (@_) {
    	$self->{SUP_REF} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{SUP_REF};
}
=head2 aspect

  Usage    - print $goa_association->aspect() or $goa_association->aspect($aspect)
  Returns  - the aspect (P, F or C)
  Args     - the aspect (P, F or C)
  Function - gets/sets the aspect
  
=cut
sub aspect {
	my $self = shift;
    if (@_) {
    	$self->{ASPECT} = shift;
	} else { # get-mode
		carp "The ID of this association is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{ASPECT};
}

=head2 description

  Usage    - print $goa_association->description() or $goa_association->description($description)
  Returns  - the description of the object (string)
  Args     - the description of the object (string)
  Function - gets/sets the description of the object
  
=cut
sub description {
	my $self = shift;
    if (@_) { 
		$self->{DESCRIPTION} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{DESCRIPTION};
}

=head2 synonym

  Usage    - print $goa_association->synonym() or $goa_association->synonym($synonym)
  Returns  - the Iternational Protein Index identifier of the object (string)
  Args     - the Iternational Protein Index identifier of the object (string)
  Function - gets/sets the Iternational Protein Index identifier of the object
  
=cut
sub synonym {
	my $self = shift;
    if (@_) { 
		$self->{SYNONYM} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{SYNONYM};
}

=head2 type

  Usage    - print $goa_association->type() or $goa_association->type($type)
  Returns  - the type of the object (here "protein")
  Args     - the type of the object (here "protein")
  Function - gets/sets the type of the object
  
=cut
sub type {
	my $self = shift;
    if (@_) { 
		$self->{TYPE} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{TYPE};
}

=head2 taxon

  Usage    - print $goa_association->taxon() or $goa_association->taxon($taxon)
  Returns  - the NCBI identifier of the biological species (string)
  Args     - the NCBI identifier of the biological species (string)
  Function - gets/sets the NCBI identifier of the biological species 
  
=cut
sub taxon {
	my $self = shift;
    if (@_) { 
		$self->{TAXON} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{TAXON};
}

=head2 date

  Usage    - print $goa_association->date() or $goa_association->date($date)
  Returns  - the date of last annotation update (string)
  Args     - the date of last annotation update (string)
  Function - gets/sets the date of last annotation update
  
=cut
sub date {
	my $self = shift;
    if (@_) { 
		$self->{DATE} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{DATE};
}

=head2 annot_src

  Usage    - print $goa_association->annot_src() or $goa_association->annot_src($annot_src)
  Returns  - the the source of the annotation (string)
  Args     - the the source of the annotation (string)
  Function - gets/sets the source of the annotation
  
=cut
sub annot_src {
	my $self = shift;
	if (@_) { 
		$self->{ANNOT_SRC} = shift;
    } else { # get-mode
		carp "The obj_src of this 'assoc' is not defined." if (!defined($self->{ASSC_ID}));
    }
    return $self->{ANNOT_SRC};
}

=head2 equals

  Usage    - print $goa_association->equals($another_association)
  Returns  - either 1(true) or 0 (false)
  Args     - the association (OBO::APO::GoaAssociation) to compare with
  Function - tells whether the two associations are identical
  
=cut
sub equals {
	my $self = shift;
	my $result =  0; 
	
	if (@_) {
		my $target = shift;
		$result = 1;
		
		my @this =  (keys %$self);
		my @that =  (keys %$target);
		foreach (@this) {croak "The value of $_ of this association is undefined" if (!defined($self->{$_}));}
		foreach (@that) {croak "The value of $_ of this association is undefined" if (!defined($target->{$_}));}
		if ($#this != $#that){
			$result = 0;
		} else {
			foreach (@this){
				$result = 0 unless ($self->{$_} eq $target->{$_});
				last if $result == 0;
			}
		}
		return $result;
	}		
}

1;    