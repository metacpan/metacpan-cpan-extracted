# $Id: IDspaceSet.pm 2014-06-06 erick.antezana $
#
# Module  : IDspaceSet.pm
# Purpose : A set of IDspaces.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Util::IDspaceSet;
# TODO This class is identical to OBO::Util::SynonymTypeDefSet

our @ISA = qw(OBO::Util::Set);
use OBO::Util::Set;

use strict;
use warnings;

=head2 contains

  Usage    - $set->contains()
  Returns  - true if this set contains the given element
  Args     - the element (OBO::Core::IDspace) to be checked
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

  Usage    - $set->equals()
  Returns  - true or false
  Args     - the set (OBO::Util::IDspaceSet) to compare with
  Function - tells whether this set is equal to the given one
  
=cut
sub equals {
	my $self = shift;
	my $result = 0; # I guess they'are NOT identical
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

=head2 remove

  Usage    - $set->remove($element)
  Returns  - the removed element
  Args     - the element (OBO::Core::IDspace) to be removed
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

1;

__END__


=head1 NAME

OBO::Util::IDspaceSet  - An implementation of a set of IDspace's.
    
=head1 SYNOPSIS

use OBO::Core::IDspace;
use OBO::Util::IDspaceSet;

# new set
my $my_set = OBO::Util::IDspaceSet->new();
$my_set->is_empty(); # should be true

# three new synonyms
my $std1 = OBO::Core::IDspace->new();
my $std2 = OBO::Core::IDspace->new();
my $std3 = OBO::Core::IDspace->new();

# filling them...
$std1->as_string("GO", "urn:lsid:bioontology.org:GO:", "gene ontology terms");
$std2->as_string("XO", "urn:lsid:bioontology.org:XO:", "x ontology terms");
$std3->as_string("YO", "urn:lsid:bioontology.org:YO:", "y ontology terms");

# tests with empty set
$my_set->remove($std1);
$my_set->size(); # should be 0
!$my_set->contains($std1)); # should be true

$my_set->add($std1);
$my_set->contains($std1); # should be true
$my_set->remove($std1);
$my_set->size(); # should be 0
!$my_set->contains($std1); # should be true

# add's
$my_set->add($std1);
$my_set->contains($std1); # should be true
$my_set->add($std2);
$my_set->contains($std2); # should be true
$my_set->add($std3);
$my_set->contains($std3); # should be true

my $std4 = OBO::Core::IDspace->new();
my $std5 = OBO::Core::IDspace->new();
my $std6 = OBO::Core::IDspace->new();

# filling them...
$std4->as_string("ZO", "urn:lsid:bioontology.org:ZO:", "z ontology terms");
$std5->as_string("AO", "urn:lsid:bioontology.org:AO:", "a ontology terms");
$std6->as_string("GO", "urn:lsid:bioontology.org:GO:", "gene ontology terms"); # repeated !!!

$my_set->add_all($std4, $std5);
my $false = $my_set->add($std6);
# $false should be 0
$my_set->contains($std4) && $my_set->contains($std5) && $my_set->contains($std6); # should be true

$my_set->add_all($std4, $std5, $std6);
$my_set->size(); # should be 5

# remove from my_set
$my_set->remove($std4);
$my_set->size(); # should be 4
!$my_set->contains($std4); # should be true

my $std7 = $std4;
my $std8 = $std5;
my $std9 = $std6;

# a second set
my $my_set2 = OBO::Util::IDspaceSet->new();

$my_set2->is_empty(); # should be true
!$my_set->equals($my_set2); # should be true

my $add_all_check = $my_set->add_all($std4, $std5, $std6);
$add_all_check = $my_set2->add_all($std7, $std8, $std9, $std1, $std2, $std3);
!$my_set2->is_empty(); # should be true
$my_set->contains($std7) && $my_set->contains($std8) && $my_set->contains($std9); # should be true
$my_set->equals($my_set2); # should be true

$my_set2->size(); # should be 5

$my_set2->clear();
$my_set2->is_empty();
$my_set2->size(); # should be 0

my $stdA = OBO::Core::IDspace->new();
my $stdB = OBO::Core::IDspace->new();

$stdA->as_string("OO", "urn:lsid:bioontology.org:OO:", "O ontology terms");
$stdB->as_string("OO", "urn:lsid:bioontology.org:OO:", "O ontology terms");

$my_set2->clear();
$my_set2->add_all($stdA, $stdB);
$my_set2->size(); # should be 1
$my_set2->contains($stdB);
$my_set2->contains($stdA);

=head1 DESCRIPTION

A set (OBO::Util::Set) of IDspace (OBO::Core::IDspace) elements.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut