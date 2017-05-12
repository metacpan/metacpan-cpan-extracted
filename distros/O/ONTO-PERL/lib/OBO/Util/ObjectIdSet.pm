# $Id: ObjectIdSet.pm 2015-02-12 erick.antezana $
#
# Module  : ObjectIdSet.pm
# Purpose : A generic set of ontology objects.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Util::ObjectIdSet;

use Carp;
use strict;
use warnings;

sub new {
	my $class       = shift;
	my $self        = {};
	$self->{MAP}    = {}; # id vs. obj
	
	bless ($self, $class);
	return $self;
}

=head2 add

  Usage    - $set->add()
  Returns  - true if the element was successfully added
  Args     - the element to be added
  Function - adds an element to this set
  
=cut

sub add {
	my ($self, $ele) = @_;
	my $result = 0; # nothing added
	if ($ele) {
		if (!$self->contains($ele)) {
			$self->{MAP}->{$ele} = $ele; 
			$result = 1; # successfully added
		}
	} else {
		# don't add repeated elements
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
		$result *= $self->add($_);
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
	my @the_set = __sort_by_id(sub {shift}, values (%{$self->{MAP}})); # I know, it is an ordered "set".
	return (!$self->is_empty())?@the_set:();
}

sub __sort_by_id {
	caller eq __PACKAGE__ or croak;
	my ($subRef, @input) = @_;
	my @result = map { $_->[0] }                           # restore original values
				sort { $a->[1] cmp $b->[1] }               # sort
				map  { [$_, &$subRef($_->id())] }          # transform: value, sortkey
				@input;
}

=head2 contains

  Usage    - $set->contains($element)
  Returns  - 1 (true) if this set contains the given element
  Args     - the element to be checked
  Function - checks if this set constains the given element
  
=cut

sub contains {
	my ($self, $target) = @_;
	return (defined $self->{MAP}->{$target})?1:0;
}

=head2 size

  Usage    - $set->size()
  Returns  - the size of this set
  Args     - none
  Function - tells the number of elements held by this set
  
=cut

sub size {
	my $self = shift;
	my $size = keys %{$self->{MAP}};
	return $size;
}

=head2 clear

  Usage    - $set->clear()
  Returns  - none
  Args     - none
  Function - clears this list
  
=cut

sub clear {
	my $self     = shift;
	$self->{MAP} = {};
}

=head2 remove

  Usage    - $set->remove($element_to_be_removed)
  Returns  - 1 (true) if this set contained the given element
  Args     - element to be removed from this set, if present
  Function - removes an element from this set if it is present
  
=cut

sub remove {
	my ($self, $element_to_be_removed) = @_;
	my $result = $self->contains($element_to_be_removed);
	delete $self->{MAP}->{$element_to_be_removed} if ($result);
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
	return ((keys(%{$self->{MAP}}) + 0) == 0);
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
	
		my @this = map ({scalar $_;} sort values %{$self->{MAP}});
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

OBO::Util::ObjectIdSet  - A Set implementation of object IDs.

=head1 SYNOPSIS

use OBO::Util::ObjectIdSet;

use strict;


my $my_set = OBO::Util::ObjectIdSet->new();


$my_set->add("APO:P0000001");

print "contains" if ($my_set->contains("APO:P0000001"));

$my_set->add_all("APO:P0000002", "APO:P0000003", "APO:P0000004");

print "contains" if ($my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000003") && $my_set->contains("APO:P0000004"));


foreach ($my_set->get_set()) {
	
	print $_, "\n";
	
}


print "\nContained!\n" if ($my_set->contains("APO:P0000001"));

my $my_set2 = OBO::Util::ObjectIdSet->new();

$my_set2->add_all("APO:P0000001", "APO:P0000002", "APO:P0000003", "APO:P0000004");

print "contains" if ($my_set2->contains("APO:P0000002") && $my_set->contains("APO:P0000003") && $my_set->contains("APO:P0000004"));

$my_set->equals($my_set2);

$my_set2->size();


$my_set2->remove("APO:P0000003");

print "contains" if ($my_set2->contains("APO:P0000001") && $my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000004"));

$my_set2->size();


$my_set2->remove("APO:P0000005");

print "contains" if ($my_set2->contains("APO:P0000001") && $my_set->contains("APO:P0000002") && $my_set->contains("APO:P0000004"));

$my_set2->size();

$my_set2->clear();

print "not contains" if (!$my_set2->contains("APO:P0000001") || !$my_set->contains("APO:P0000002") || !$my_set->contains("APO:P0000004"));

$my_set2->size();

$my_set2->is_empty();

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