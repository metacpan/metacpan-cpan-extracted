# $Id: GoaAssociationSet.pm 2010-09-29 erick.antezana $
#
# Module  : GoaAssociationSet.pm
# Purpose : GOA association set.
# License : Copyright (c) 2006-2015 by ONTO-perl. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.

package OBO::APO::GoaAssociationSet;
our @ISA = qw(OBO::Util::Set); # TODO change inheritence

=head1 NAME

OBO::APO::GoaAssociationSet - A GoaAssociationSet implementation
   
=head1 SYNOPSIS

use OBO::APO::GoaAssociationSet;
use OBO::APO::GoaAssociation;
use strict;

my $my_set = OBO::APO::GoaAssociationSet->new();

# three new goa_association's
my $goa_association1 = OBO::APO::GoaAssociation->new();
my $goa_association2 = OBO::APO::GoaAssociation->new();
my $goa_association3 = OBO::APO::GoaAssociation->new();

$goa_association1->assc_id("APO:vm");
$goa_association2->assc_id("APO:ls");
$goa_association3->assc_id("APO:ea");

# remove from my_set
$my_set->remove($goa_association1);
$my_set->add($goa_association1);
$my_set->remove($goa_association1);

### set versions ###
$my_set->add($goa_association1);
$my_set->add($goa_association2);
$my_set->add($goa_association3);

my $goa_association4 = OBO::APO::GoaAssociation->new();
my $goa_association5 = OBO::APO::GoaAssociation->new();
my $goa_association6 = OBO::APO::GoaAssociation->new();

$goa_association4->assc_id("APO:ef");
$goa_association5->assc_id("APO:sz");
$goa_association6->assc_id("APO:qa");

$my_set->add_all($goa_association4, $goa_association5, $goa_association6);

$my_set->add_all($goa_association4, $goa_association5, $goa_association6);

# remove from my_set
$my_set->remove($goa_association4);

my $goa_association7 = $goa_association4;
my $goa_association8 = $goa_association5;
my $goa_association9 = $goa_association6;

my $my_set2 = OBO::APO::GoaAssociationSet->new();

$my_set->add_all($goa_association4, $goa_association5, $goa_association6);
$my_set2->add_all($goa_association7, $goa_association8, $goa_association9, $goa_association1, $goa_association2, $goa_association3);

$my_set2->clear();

=head1 DESCRIPTION

A set (OBO::Util::Set) of goa_association records.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by ONTO-perl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

use OBO::Util::Set;
use strict;
use warnings;
use Carp;

=head2 add

 Usage    - $set->add($goa_association)
 Returns  - true if the element was successfully added
 Args     - the element (OBO::APO::GoaAssociation) to be added
 Function - adds an element to this set

=cut
sub add {
	my $self = shift;
	my $result = 0; # nothing added
	if (@_) {
		my $ele = shift;
		if ( !$self -> contains($ele) ) {
			push @{$self->{SET}}, $ele;
			$result = 1; # successfully added
		}
	}
	return $result;
}

=head2 add_unique

 Usage    - $set->add_unique($goa_association)
 Returns  - 1 (the element is always added)
 Args     - the element (OBO::APO::GoaAssociation) to be added which is known to be unique!
 Function - adds an element to this set
 Remark   - this function should be used when the element to be added is known to be unique,
 			this function has a tremendous impact on the performance (compared to simply add())  

=cut
sub add_unique {
	my $self = shift;
	my $result = 0; # nothing added
	if (@_) {
		my $ele = shift;
		push @{$self->{SET}}, $ele;
	}
	return 1;
}

=head2 remove

 Usage    - $set->remove($element)
 Returns  - the removed element (OBO::APO::GoaAssociation)
 Args     - the element to be removed (OBO::APO::GoaAssociation)
 Function - removes an element from this set

=cut
sub remove {
   my $self = shift;
   my $result = undef;
   if (@_) {          
	my $ele = shift;
       if ($self->size() > 0) {
           for (my $i = 0; $i < scalar(@{$self->{SET}}); $i++){
               my $e = ${$self->{SET}}[$i];
               if ($ele->equals($e)) {
                   if ($self->size() > 1) {
                       my $first_elem = shift (@{$self->{SET}});
                       ${$self->{SET}}[$i-1] = $first_elem;
                   } elsif ($self->size() == 1) {
                       shift (@{$self->{SET}});
                   }
                   $result = $ele;
                   last;
               }
           }
       }
   }
   return $result;
}

=head2 remove_duplicates

 Usage    - $set->remove_duplicates()
 Returns  - a set object (OBO::APO::GoaAssociationSet) 
 Args     - none 
 Function - eliminates redundency in a GOA association set object (OBO::APO::GoaAssociationSet)

=cut
sub remove_duplicates {
	my $self = shift;
	my @list = @{$self->{SET}};
	my @set = ();
	while (scalar (@list)) {
		my $ele = pop(@list);
		my $result = 0;
		foreach (@list) {
			if ($ele->equals($_)) {
				$result = 1; 
				last; 
			}
		}
		unshift @set, $ele if $result == 0;
	}
	@{$self->{SET}} = @set;
	return $self;
}


=head2 contains

 Usage    - $set->contains($goa_association)
 Returns  - either 1(true) or 0 (false)
 Args     - the element (OBO::APO::GoaAssociation) to be checked
 Function - checks if this set constains the given element

=cut
sub contains {
	my $self = shift;
	my $result = 0;
	if (@_){
		my $target = shift;
		foreach my $ele (@{$self->{SET}}){
			if ($target->equals($ele)) {
				$result = 1;
				last;
			}
		}
	}
	return $result;
}

=head2 equals

 Usage    - $set->equals($another_goa_assocations_set)
 Returns  - either 1 (true) or 0 (false)
 Args     - the set (OBO::APO::GoaAssociationSet) to compare with
 Function - tells whether this set is equal to the given one

=cut
sub equals {
   my $self = shift;
   my $result = 0; # I guess they'are NOT identical
     if (@_) {
       my $other_set = shift;
		my %count = ();
		my @this = @{$self->{SET}};
		my @that = $other_set->get_set();

       if ($#this == $#that) {
           if ($#this != -1) {
               foreach (@this, @that) {
                   $count{	$_->annot_src().
                   			$_->aspect().
                   			$_->assc_id().
                   			$_->date().
                   			$_->description().
                   			$_->evid_code().
                   			$_->go_id().
                   			$_->obj_id().
                   			$_->obj_src().
                   			$_->obj_symb().
                   			$_->qualifier().
                   			$_->refer().
                   			$_->sup_ref().
                   			$_->synonym().
                   			$_->taxon().
                   			$_->type()}++;
               }
               foreach my $count (values %count) {
                   if ($count != 2) {
                       $result = 0;
                       last;
                   } else {
                       $result = 1;
                   }
               }
           } else {
               $result = 1; # they are equal: empty arrays
           }
       }
   }
   return $result;
}

1;