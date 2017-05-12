# $Id: Set.pm 2014-09-29 erick.antezana $
#
# Module  : Set.pm
# Purpose : An implementation of a Set of scalars.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
# TODO implement function 'eliminate duplicates', see GoaAssociationSet.t
package OBO::Util::Set;

use strict;
use warnings;

sub new {
	my $class        = shift;
	my $self         = {};
	@{$self->{SET}}  = ();
	
	bless ($self, $class);
	return $self;
}

=head2 add

  Usage    - $set->add($element)
  Returns  - true if the element was successfully added
  Args     - the element to be added
  Function - adds an element to this set
  
=cut

sub add {
	my ($self, $ele) = @_;
	my $result = 0; # nothing added
	if ($ele) {
		if ( !$self -> contains($ele) ) {
			push @{$self->{SET}}, $ele;
			$result = 1; # successfully added
		}
	}
	return $result;
}

=head2 add_all

  Usage    - $set->add_all($ele1, $ele2, $ele3, ...)
  Returns  - true if the elements were successfully added
  Args     - the elements to be added
  Function - adds the given elements to this set
  
=cut

sub add_all {
	my $self = shift;
	my $result = 1; # something added
	foreach (@_) {
		$result *= $self->add ($_);
	}
	return $result;
}

=head2 get_set

  Usage    - $set->get_set()
  Returns  - this set
  Args     - none
  Function - returns this set
  
=cut

sub get_set {
	my $self = shift;
	return (!$self->is_empty())?@{$self->{SET}}:();
}

=head2 contains

  Usage    - $set->contains($ele)
  Returns  - 1 (true) if this set contains the given element
  Args     - the element to be checked
  Function - checks if this set constains the given element
  
=cut

sub contains {
	my ($self, $target) = @_;
	my $result = 0;
	foreach my $ele ( @{$self->{SET}}) {
		if ( $target eq $ele) {
			$result = 1;
			last;
		}
	}
	return $result;
}

=head2 size

  Usage    - $set->size()
  Returns  - the size of this set
  Args     - none
  Function - tells the number of elements held by this set
  
=cut

sub size {
	my $self = shift;
	return $#{$self->{SET}} + 1;
}

=head2 clear

  Usage    - $set->clear()
  Returns  - none
  Args     - none
  Function - clears this list
  
=cut

sub clear {
	my $self = shift;
	@{$self->{SET}} = ();
}

=head2 remove

  Usage    - $set->remove($element_to_be_removed)
  Returns  - 1 (true) if this set contained the given element
  Args     - element to be removed from this set, if present
  Function - removes an element from this set if it is present
  
=cut

sub remove {
	my $self = shift;
	my $element_to_be_removed = shift;
	my $result = $self->contains($element_to_be_removed);
	if ($result) {
		for (my $i = 0; $i <= $#{$self->{SET}}; $i++) {
			if ($element_to_be_removed eq ${$self->{SET}}[$i]) {
				splice(@{$self->{SET}}, $i, 1); # erase the slot
				last;
			}
		}
	}
	return $result;
}

=head2 is_empty

  Usage    - $set->is_empty()
  Returns  - true if this set is empty
  Args     - none
  Function - checks if this set is empty
  
=cut

sub is_empty {
	my $self = shift;
	return ($#{$self->{SET}} == -1);
}

=head2 equals

  Usage    - $set->equals($another_set)
  Returns  - either 1 (true) or 0 (false)
  Args     - the set (Core::Util::Set) to compare with
  Function - tells whether this set is equal to the given one
  
=cut

sub equals {
	my $self = shift;
	my $result = 0; # I initially guess they're NOT identical
	if (@_) {
		my $other_set = shift;
		my %count = ();
	
		my @this = map ({scalar $_;} @{$self->{SET}});
		my @that = map ({scalar $_;} $other_set->get_set());
		
		if ($#this == $#that) {
			foreach (@this, @that) {
				$count{$_}++;
			}
			foreach my $count (sort values %count) {
				if ($count != 2) {
					$result = 0;
					last;
				} else {
					$result = 1;
				}
			}
		}
	}
	return $result;
}

1;

__END__


=head1 NAME

OBO::Util::Set - An implementation of a set of scalars (sensu PERL).
    
=head1 SYNOPSIS

use OBO::Util::Set;

use strict;

my $my_set = OBO::Util::Set->new();

$my_set->add("APO:P0000001");

print "contains" if ($my_set->contains("APO:P0000001"));

$my_set->add_all("APO:P0000002", "APO:P0000003", "APO:P0000004");

print "contains" if ($my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000003") && $my_set->contains("APO:P0000004"));

foreach ($my_set->get_set()) {

	print $_, "\n";

}

print "\nContained!\n" if ($my_set->contains("APO:P0000001"));

my $my_set2 = OBO::Util::Set->new();

$my_set2->add_all("APO:P0000001", "APO:P0000002", "APO:P0000003", "APO:P0000004");

print "contains" if ($my_set2->contains("APO:P0000002") && $my_set->contains("APO:P0000003") && $my_set->contains("APO:P0000004"));

$my_set->equals($my_set2);

$my_set2->size() == 4;

$my_set2->remove("APO:P0000003");

print "contains" if ($my_set2->contains("APO:P0000001") && $my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000004"));

$my_set2->size() == 3;

$my_set2->remove("APO:P0000005");

print "contains" if ($my_set2->contains("APO:P0000001") && $my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000004"));

$my_set2->size() == 3;

$my_set2->clear();

print "not contains" if (!$my_set2->contains("APO:P0000001") || !$my_set->contains("APO:P0000002") || !$my_set->contains("APO:P0000004"));

$my_set2->size() == 0;

if ($my_set2->is_empty()) {
	print "my_set2 is empty";
}


=head1 DESCRIPTION

A collection that contains no duplicate elements. More formally, sets contain no 
pair of elements $e1 and $e2 such that $e1->equals($e2). As implied by its name, 
this interface models the mathematical set abstraction.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut